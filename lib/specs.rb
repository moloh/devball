require 'lib/atom'
require 'lib/package'
require 'lib/dependencies'
require 'lib/error'

module Devball

class Specs
	def Specs.init
		@@specs = {}
		@@dbs = {}

		# create spec locations database
		Dir.foreach(Config._SPECS) do |file|
			next if file.index(".spec", -5).nil?

			# parse atom (remove extension)
			name, version, _ = Atom.parse_name(file)
			name_sym = name.to_sym

			# validate that we haev version
			raise Error::Name.new(file) if version.nil?

			# add to spec list
			@@specs[name_sym] ||= {}
			@@specs[name_sym][version] = file
		end if File.directory?(Config._SPECS)

		# create db spec database
		Dir.foreach(Config._DB) do |directory|
			next if directory.index(".spec", -5).nil?

			# parse atom (remove extension)
			atom_t = Atom.parse_name(directory)
			name_sym = atom_t[0].to_sym

			# validate that we don't have two versions installed
			if (@@dbs.key?(name_sym))
				message = "multiple installed versions => #{directory}"
				raise Error::Internal.new(message)
			end

			# store full spec instead of name
			atom_t[0] = directory

			# add to spec list
			@@dbs[name_sym] = atom_t
		end if File.directory?(Config._DB)
	end

	def Specs.specs
		return @@specs
	end

	def Specs.locate(atom)
		return Specs.locate_atom(Atom.parse(atom))
	end

	def Specs.locate_atom(atom)
		# get spec
		specs = @@specs[atom.name.to_sym]

		# check if spec is available
		raise Error::Missing.new(atom) if specs.nil?

		# extract all matching entries
		vers = atom.matches(specs)

		# check if ver is available
		raise Error::Missing.new(atom) if vers.empty?

		# get maximum version
		return vers[0][1] if vers.length == 1
		return vers.max {|a,b| a[0] <=> b[0]}[1]
	end

	def Specs.locate_db(atom)
		# get spec
		atom = Atom.parse(atom)
		atom_t = @@dbs[atom.name.to_sym]

		raise Error::Missing.new(atom) if atom_t.nil?
		return atom_t
	end

	def Specs.locate_db_name(name)
		return @@dbs[name.to_sym]
	end

	def Specs.list_db(atom = nil, type = :files)
		if (atom.nil?)
			return @@dbs.values.map do |atom_t|
				"#{atom_t[0]} [#{Package::Features.read(atom_t[0])}]"
			end
		end

		# locate package
		atom_t = Specs.locate_db(atom)

		case type
		when :files
			return Package::Contents.read(atom_t[0])
		end
	end

	def Specs.list_db_owner(target)
		owner = []

		# scan contents of each installed package
		@@dbs.values.each do |atom_t|
			contents = Package::Contents.read(atom_t[0])
			contents.each do |file|
				unless file.index(target).nil?
					owner << "#{atom_t[0]} (#{file})"
				end
			end
		end

		return owner
	end

	def Specs.install(name, options)
		pkg = Package.new("#{Config._SPECS}/#{name}")

		# get all install dependencies
		dependencies, = Dependencies.resolve(pkg)

		# check for conflicts
		names = dependencies.map {|pkg| pkg._NAME}
		if (dependencies.length != names.uniq.length)
			specs = dependencies.map {|pkg| pkg._SPEC}
			raise Error::Conflict.new("#{pkg}\n * #{specs.join("\n * ")}\n")
		end

		# remove available packages
		dependencies.map! do |pkg|
			# get corresponding db entry
			name,version = Specs.locate_db_name(pkg._NAME)

			# check version
			if (version.nil? || version < pkg._VERSION)
				pkg
			else
				nil
			end
		end

		# remove all nils
		dependencies.compact!

		# we should force installation
		if (options[:force])
			dependencies << pkg
		end

		if (options[:pretend])
			puts ">>> Packages to install:"
			dependencies.reverse.each {|pkg| puts " * #{pkg}"}
		else
			return if dependencies.empty?

			# install packages
			dependencies.each {|package| package.run_action(:install, options)}

			if (options[:world])
				puts ">>> Adding #{name} to world"
				world = "#{Config._DB}/world"
				(Set.read(world) << name).write(world)
			end
		end
	end

	def Specs.uninstall(name, options)
		package = Package.new("#{Config._DB}/#{name}/#{name}")
		package.run_action(:uninstall, options)

		# remove package from world
		puts ">>> Removing #{name} from world"
		world = "#{Config._DB}/world"
		(Set.read(world) >> name).write(world)
	end
end

end # module Devball


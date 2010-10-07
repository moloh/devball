require 'lib/atom'
require 'lib/package'
require 'lib/error'

module Devball

class Dependencies
	def Dependencies.resolve(package)
		# compute dependencies
		deps = {:all => [], :lookup => {}}
		resolve_internal(package, deps)
		deps[:all] << package

		# clean internal structure
		list = deps[:all]

		deps.delete(:all)
		deps.delete(:lookup)

		# return list and complete tree
		return list, deps
	end

	def Dependencies.resolve_internal(package, deps)
		# initialize deps for package
		deps[package] = []

		# parse and cache all atoms
		package._DEPENDENCIES.collect! {|dep| Atom.parse(dep)}

		# search for package dependencies
		package._DEPENDENCIES.reverse_each do |atom|

			# locate spec for dependency
			begin
				name = Specs.locate_atom(atom)
			rescue Error::Missing
				raise Error::Dependencies.new("#{package._SPEC} (#{$!})")
			end

			# add dependency if not already there
			unless (deps[:lookup].has_key?(atom.name.hash))
				deps[:lookup][atom.name.hash] = nil

				# create package object
				pkg = Package.new("#{Config._SPECS}/#{name}")

				# do recursive descent
				resolve_internal(pkg, deps)

				# update pkg
				deps[:all] << pkg
				deps[package] << pkg
			end
		end
	end
	private_class_method :resolve_internal

end

end # module Devball


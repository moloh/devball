require 'lib/version'
require 'lib/error'
require 'lib/enums'

module Devball

class Atom
	attr_reader :name, :version, :options

	def initialize(name, version, options = nil)
		@name = name
		@version = version
		@options = options || {}
	end

	def inspect
		# process instance variables
		map = self.instance_variables.map {|var|
			"#{var}=#{self.instance_variable_get(var).inspect}"
		}

		"\#<#{self.class} #{map.join(", ")}>"
	end

	def to_s
		unless (@options.key?(:match))
			return "#{@name}" unless @version
			return "#{@name}-#{@version}"
		else
			return "#{@options[:match].nick}#{@name}" unless @version
			return "#{@options[:match].nick}#{@name}-#{@version}"
		end
	end

	# Check whether +version+ matches atom
	def match(version)
		return true unless @options[:match]
		case @options[:match]
		when Match::Equal
			return @version == version
		when Match::GreaterEqual
			return @version <= version
		when Match::Greater
			return @version < version
		when Match::LowerEqual
			return @version >= version
		when Match::Lower
			return @version > version
		end
	end

	# Return all +versions+ that match atom
	def matches(versions)
		return versions.to_a unless @options[:match]
		case @options[:match]
		when Match::Equal then
			return versions.find_all {|v,_| @version == v}
		when Match::GreaterEqual then
			return versions.find_all {|v,_| @version <= v}
		when Match::Greater then
			return versions.find_all {|v,_| @version < v}
		when Match::LowerEqual then
			return versions.find_all {|v,_| @version >= v}
		when Match::Lower then
			return versions.find_all {|v,_| @version > v}
		end
	end

	def Atom.parse(atom)
		name = nil
		version = nil
		options = {}
		first, last = 0, 0

		# check prefix
		case atom[0]
		when ?=
			raise Error::Atom.new(atom) if (atom[1] == ?> || atom[1] == ?<)
			options[:match] = Match::Equal
			first = 1
		when ?>
			if atom[1] == ?=
				options[:match] = Match::GreaterEqual
				first = 2
			else
				options[:match] = Match::Greater
				first = 1
			end
		when ?<
			if atom[1] == ?=
				options[:match] = Match::LowerEqual
				first = 2
			else
				options[:match] = Match::Lower
				first = 1
			end
		end

		if last = atom.rindex(?-)
			if (atom[last+1] >= ?0 && atom[last+1] <= ?9)
				version = Version.new(atom[last + 1, atom.length])
				name = atom[first, last - first]
			else
				name = atom[first, atom.length]
			end
		else
			name = atom[first, atom.length]
		end

		# validate version selector if version present
		raise Error::Match.new(atom) if version && !options[:match]

		return nil unless name
		return Atom.new(name, version, options)
	end

	# parse file named +atom+ (including ".spec" extension)
	# returns [name, version, inherit] array
	def Atom.parse_name(atom)
		pos = 0

		if pos = atom.rindex(?-, -6)
			# move to next character
			pos += 1

			if (atom[pos] >= ?0 && atom[pos] <= ?9)
				name = atom[0, pos - 1]
				version = Version.new(atom[pos..-6])
			else
				name = atom[0..-6]
			end

			if name[-1] == ?}
				pos = name.rindex(?{)
				inherit = name[pos + 1..-2]
				name.slice!(pos, name.length)
				[name, version, inherit]
			else
				[name, version]
			end
		else
			[atom[0..-6]]
		end
	end
end # class Atom

end # module Devball


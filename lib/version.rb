require 'lib/error'

module Devball

class Version
	include Comparable

	attr_reader :parts, :letter, :suffix

	def initialize(version)
		@parts = []

		# extract all parts
		parts = version.split('.')
		raise Error::Version.new(version) unless parts.length > 0

		# store last part
		last = parts.slice!(-1)

		# validate all parts
		parts.each {|part|
			@parts << part.to_i
			if @parts.last == 0 and part != "0"
				raise Error::Version.new(version)
			end
		}

		# process suffix
		if pos = last.index("_")
			# extract suffix and remove "_" character
			part = last.slice!(pos + 1, last.length)
			last.slice!(-1)

			# find supported postfix
			type = Suffix.get_nick_prefix(part)
			value = part[type.nick.length, part.length].to_i
			@suffix = type.clone_with_data(value)
		end

		# check for [a-z] as last character
		if last[-1] >= ?a && last[-1] <= ?z
			@letter = last[-1].chr
			last.slice!(-1)
		end

		@parts << last.to_i
		if @parts.last == 0 and last != "0"
			raise Error::Version.new(version)
		end
	end

	def inspect
		"\#<#{self.class} \"#{self}\">"
	end

	def to_s
		if (@suffix.nil?)
			"#{@parts.join(".")}#{@letter}"
		elsif (@suffix.data.nil?)
			"#{@parts.join(".")}#{@letter}_#{@suffix.nick}"
		else
			"#{@parts.join(".")}#{@letter}_#{@suffix.nick}#{@suffix.data}"
		end
	end

	def format(parts = '.', letter = '', suffix = '_')
		if (@letter.nil?)
			if (@suffix.nil?)
				"#{@parts.join(parts)}"
			elsif (@suffix.data.nil?)
				"#{@parts.join(parts)}#{suffix}#{@suffix.nick}"
			else
				"#{@parts.join(parts)}#{suffix}#{@suffix.nick}#{@suffix.data}"
			end
		else
			if (@suffix.nil?)
				"#{@parts.join(parts)}#{letter}#{@letter}"
			elsif (@suffix.data.nil?)
				"#{@parts.join(parts)}#{letter}#{@letter}#{suffix}#{@suffix.nick}"
			else
				"#{@parts.join(parts)}#{letter}#{@letter}#{suffix}#{@suffix.nick}#{@suffix.data}"
			end
		end
	end

	def eql?(other)
		return self == other
	end

	def <=>(other)
		if @parts.length < other.parts.length
			@parts.each_with_index {|value, i|
				return value <=> other.parts[i] unless value == other.parts[i]
			}
			return -1
		elsif @parts.length == other.parts.length
			other.parts.each_with_index {|value, i|
				return @parts[i] <=> value unless @parts[i] == value
			}

			if @letter || other.letter
				return -1 if @letter.nil?
				return 1 if other.letter.nil?
				return @letter <=> other.letter unless @letter == other.letter
			end

			if @suffix || other.suffix
				return other.suffix.is?(Suffix::P) ? -1 : 1 if @suffix.nil?
				return @suffix.is?(Suffix::P) ? 1 : -1 if other.suffix.nil?

				if @suffix == other.suffix
					return @suffix.data <=> other.suffix.data
				else
					return @suffix <=> other.suffix
				end
			end

			return 0
		else # @parts.length > other.parts.length
			other.parts.each_with_index {|value, i|
				return @parts[i] <=> value unless @parts[i] == value
			}
			return 1
		end
	end
end

end # module Devball


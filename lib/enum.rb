
module Devball

class Enum
	def initialize
	end
	protected :initialize

	def Enum.inspect
		@enums.inspect
	end

	def Enum.enums
		@enums
	end

	def Enum.class_name
		index = self.name.rindex("::")
		return self.name if index.nil?
		return self.name[index + 2, self.name.length]
	end

	def Enum.enum(*opts)
		value, last = nil, -1

		# init enums store
		@names ||= {}
		@vals ||= {}
		@enums ||= []

		opts.each {|opt|
			obj = case opt
			when Symbol
				# setup value for enum
				value = last + 1

				# store last value
				last = value

				# setup enum value object
				Value.new(value, opt, nil)
			when Array

				# setup enum value object properties
				vals = [last + 1, opt[0], nil]

				opt.slice!(0)
				opt.each {|val|
					case val
					when Integer
						vals[0] = val
					when String, Symbol, Regexp
						vals[2] = val
					else
						raise TypeError
					end
				}

				# store last value
				last = vals[0]

				# setup enum value object
				Value.new(*vals)
			else
				raise TypeError
			end

			@names[obj.name] = obj
			@vals[obj.value] = obj
			@enums << obj
		}

		# setup enum constants
		@enums.each {|obj|
			unless self.const_defined?(obj.name)
				self.const_set(obj.name, obj)
				obj.instance_eval "def enum_name; \"#{class_name}\"; end"
			end
		}
	end

	def Enum.get_value(value)
		@vals[value]
	end

	def Enum.get_name(name)
		@names[name]
	end

	def Enum.get_nick(nick)
		# find matching nick
		@enums.each do |obj|
			return obj if obj.nick == nick
		end

		return nil
	end

	def Enum.get_nick_prefix(nick)
		# find matching nick prefix
		@enums.each do |obj|
			return obj if nick.index(obj.nick) == 0
		end

		return nil
	end

	def Enum.get_nick_match(nick)
		# find matching nick
		@enums.each do |obj|
			return obj if nick =~ obj.nick
		end

		return nil
	end

	class Value
		attr_reader :value, :name, :nick, :data

		def initialize(value, name, nick = nil, data = nil)
			# validate types
			raise TypeError unless value.kind_of?(Integer)
			raise TypeError unless name.kind_of?(Symbol)

			@value = value
			@name = name
			@nick = nick.nil? ? name : nick
			@data = data unless data.nil?
		end
		protected :initialize

		def clone_with_data(data = nil)
			# clone value with optional data
			value = Value.new(@value, @name, @nick, data)

			# setup instance specific enum_name
			value.instance_eval "def enum_name; \"#{enum_name}\"; end"

			return value
		end

		def inspect
			return "#{enum_name}::#{@name}(#{@value})" unless @data
			return "#{enum_name}::#{@name}(#{@value},#{@data})"
		end

		def class_name
			"#{enum_name}::#{@name}"
		end

		def to_s
			@name.to_s
		end

		def to_i
			@value
		end

		def ==(other)
			return false if other.nil?
			@value == other.value
		end

		def <=>(other)
			return 1 if other.nil?
			@value <=> other.value
		end

		def is?(other)
			return false if other.nil?
			@value == other.value
		end
	end
end

end # module Devball


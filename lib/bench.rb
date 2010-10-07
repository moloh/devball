require 'lib/options'
require 'lib/config'
require 'lib/atom'
require 'lib/specs'

module Devball
module Base

class Bench
	def Bench.init
		@@time = {}
		@@calls = {}
	end

	def Bench.time
		@@time
	end

	def Bench.calls
		@@calls
	end

	def Bench.stats
		@@time.sort {|a,b|
			# sort by key name
			a[0].to_s <=> b[0].to_s
		}.each {|key, value|
			# print sorted stats
			puts "%-40s %9.6f %12.6f" %
				[key, value / @@calls[key], value]
		}
	end

	def Bench.store(stat, data)
		@@calls[stat] = 0 unless @@calls.has_key?(stat)
		@@time[stat] = 0 unless @@time.has_key?(stat)

		@@calls[stat] += 1
		@@time[stat] += data
	end

	def Bench.class_method(klass, method)
		# benchmark only in bench mode
		return unless Options.bench

		klass.class_eval "class << self
			alias :\"__#{method}\" :#{method}
			def #{method}(*args, &block)
				stamp = Time.now.to_f
				retval = send(:\"__#{method}\", *args, &block)
				stamp = Time.now.to_f - stamp
				Bench.store(:\"#{klass.name}.#{method}\", stamp)
				retval
			end
		end"
	end

	def Bench.method(klass, method)
		# benchmark only in bench mode
		return unless Options.bench

		klass.class_eval "alias :\"__#{method}\" :#{method}
		def #{method}(*args, &block)
			stamp = Time.now.to_f
			retval = send(:\"__#{method}\", *args, &block)
			stamp = Time.now.to_f - stamp
			Bench.store(:\"#{klass.name}.#{method}\", stamp)
			retval
		end"
	end
end

end # module Base

class Bench < Base::Bench
	init
end

# benchmark class methods
Bench.class_method(Base::Config, :init)
Bench.class_method(Atom, :parse)
Bench.class_method(Atom, :parse_name)
Bench.class_method(Enum, :enum)
Bench.class_method(Specs, :init)
Bench.class_method(Specs, :locate_atom)

# benchmark instance methods
Bench.method(Version, :initialize)
Bench.method(Version, :=~)
Bench.method(Version, :<=>)

end # module Devball


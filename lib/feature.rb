require 'lib/config'

module Devball
module Base

class Feature
	def Feature.inspect
		data = @@data.map {|key,val| "#{"-" unless val}#{key}"}
		return "\#<#{self.name} [#{data.join(" ")}]>" unless data.nil?
		return "\#<#{self.name}>"
	end

	def Feature.init(value)
		@@data = {}

		value.split.each {|feature|
			if (feature[0] == ?-)
				feature.slice!(0)
				@@data[feature.to_sym] = false
			else
				@@data[feature.to_sym] = true
			end
		}

		# override setting when set in environment
		unless ENV["FEATURES"].nil?
			ENV["FEATURES"].split.each {|feature|
				if (feature[0] == ?-)
					feature.slice!(0)
					@@data[feature.to_sym] = false
				else
					@@data[feature.to_sym] = true
				end
			}
		end
	end

	def Feature.[](name)
		return @@data[name.to_sym]
	end
end

end # module Base

class Feature < Base::Feature
	init(Config._FEATURES)
end

end # module Devball


require 'lib/config'

module Devball

class Package
	class Features < Array

		def inspect
			"\#<#{self.class} [#{self}]>"
		end

		def to_s
			join(" ")
		end

		def Features.read(name)
			line = File.open("#{Config._DB}/#{name}/FEATURES").gets
			return Features.new(line.split) unless line.nil?
			return Features.new
		end

		def Features.parse(value)
			features = Features.new

			value.split.each {|feature|
				if (feature[0] == ?+)
					feature.slice!(0)

					# check if feature is globally disabled
					next if Config.feature?(feature.to_sym) == false

					# mark feature as active
					features << feature.to_sym
				else
					# check if feature is globally enabled
					next unless Config.feature?(feature.to_sym) == true

					# mark feature as active
					features << feature.to_sym
				end
			}

			return features
		end
	end

	def feature_with(feature, name = nil)
		initialize_features
		if (_FEATURES.include?(feature.to_sym))
			return " --with-#{name}" unless name.nil?
			return " --with-#{feature}"
		else
			return " --without-#{name}" unless name.nil?
			return " --without-#{feature}"
		end
	end

	def feature_enable(feature, name = nil)
		initialize_features
		if (_FEATURES.include?(feature.to_sym))
			return " --enable-#{name}" unless name.nil?
			return " --enable-#{feature}"
		else
			return " --disable-#{name}" unless name.nil?
			return " --disable-#{feature}"
		end
	end

	def feature?(feature, if_true = nil, if_false = nil)
		initialize_features
		if (_FEATURES.include?(feature.to_sym))
			return if_true unless if_true.nil?
			return true
		else
			return if_false unless if_false.nil?
			return false
		end
	end
end

end # module Devball


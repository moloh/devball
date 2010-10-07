
module Devball

class Package
	def _DEPENDENCIES! (*values)
		@_DEPENDENCIES.concat(values)
	end

	def _URLS! (*values)
		values.each do |value|
			case value
			when String
				@_URLS[value] = File.basename(value)
			when Hash
				@_URLS.merge!(value)
			end
		end
	end

	def _FILES! (*values)
		@_FILES.concat(values)
	end

	def _PATCHES! (*values)
		@_PATCHES.concat(values)
	end

	def _FEATURES! (*values)
		@_FEATURES << " " unless @_FEATURES.empty?
		@_FEATURES << values.join(" ")
	end

	def _SRCDIR! (value)
		@_SRCDIR = value
	end

	def _CFLAGS! (value)
		@_CFLAGS = value
		ENV["CFLAGS"] = value
	end

	def _CXXFLAGS! (value)
		@_CXXFLAGS = value
		ENV["CXXFLAGS"] = value
	end

	def _LDFLAGS! (value)
		@_LDFLAGS = value
		ENV["LDFLAGS"] = value
	end
end

end # module Devball


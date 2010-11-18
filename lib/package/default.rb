require 'fileutils'

module Devball

class Package
	def default_src_fetch
		fetch _URLS
	end

	def default_src_unpack
		unpack [_FILES, _URLS.values]
	end

	def default_src_prepare
		patch _PATCHES
	end

	def default_src_configure
		configure
	end

	def default_src_compile
		make
	end

	def default_src_install
		make %Q{DESTDIR="#{_D}" install}
	end

	alias :src_fetch :default_src_fetch
	alias :src_unpack :default_src_unpack
	alias :src_prepare :default_src_prepare
	alias :src_configure :default_src_configure
	alias :src_compile :default_src_compile
	alias :src_install :default_src_install
end

end # module Devball


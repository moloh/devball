require 'lib/error'
require 'lib/util'

require 'fileutils'
require 'net/http'

module Devball

class Package
	def fetch(urls)
		# process input
		case urls
		when String then urls = [urls]
		when Array  then urls.flatten!
		end

		urls.each do |url, file|
			# specify files name
			file = File.basename(url) if file.nil?

			# check if file is already present
			if (File.exist?("#{_DISTFILESDIR}/#{file}") ||
				File.exist?("#{_FILESDIR}/#{file}"))
				next
			end

			puts ">>> Fetching #{file} from #{url}"
			http_download "#{_DISTFILESDIR}/#{file}", url
		end
	end

	def unpack(files)
		# process input
		case files
		when String then files = [files]
		when Array  then files.flatten!
		end

		# unpack all files
		files.each do |file|
			puts ">>> Unpacking #{file} to #{Dir.pwd}"

			# exact path or relative to _FILESDIR
			path = Util.locate_file_in_dirs(file, _FILESDIR, _DISTFILESDIR)

			# execute correct unpack command
			case File.extname(file)
			when ".tar"
				command = %Q{tar xof "#{path}"}
			when ".tgz"
				command = %Q{tar xozf "#{path}"}
			when ".gz"
				if (file[-7,4] == ".tar")
					command = %Q{gzip -dc "#{path}" | tar xof -}
				else
					command = %Q{gzip -dc "#{path}"}
				end
			when ".bz2"
				if (file[-8,4] == ".tar")
					command = %Q{bzip2 -dc "#{path}" | tar xof -}
				else
					command = %Q{bzip2 -dc "#{path}"}
				end
			else
				raise Error::Package.new("unknown archive type: #{file}")
			end

			retval = Util.run command, STDOUT
			raise Error::Package.new("unpack error") if retval != 0
		end
	end

	def patch(files, options = "")
		# process input
		case files
		when String then files = [files]
		when Array  then files.flatten!
		end

		# expand directories or paths
		files.map! do |file|
			# exact path or relative to _PATCHESDIR
			path = Util.locate_file_in_dirs(file, _PATCHESDIR)

			if (File.directory?(path))
				Dir["#{path}/*"].sort
			else
				path
			end
		end

		# flatten directories
		files.flatten!

		files.each do |file|
			puts ">>> Applying patch #{File.basename(file)}"

			command = case File.extname(file)
			when ".gz" then "gzip -dc"
			when ".diff", ".patch" then "cat"
			else "cat"
			end << %Q{ "#{file}" | patch #{options}}

			# guess correct -p
			if (options.index("-p").nil?)
				level = nil
				5.times do |n|
					c = "#{command} -p#{n} --dry-run 2>/dev/null"
					retval = Util.run c, Util::DEVNULL
					next if retval != 0

					# we found correct -p
					level = n
					break
				end
				raise Error::Package.new("patch error") if level.nil?
				options.insert(0, "-p#{level} ")
			end

			retval = Util.run "#{command} --quiet #{options}", STDOUT
			raise Error::Package.new("patch error") if retval != 0
		end
	end

	def autoreconf
		puts ">>> Running auroreconf"
		exec_v "aclocal", true
		exec_v "autoheader", true
		exec_v "automake --add-missing --copy", true if File.exist?("Makefile.am")
		exec_v "autoconf", true
		exec_v "#{"g" if platform?(Platform::Darwin)}libtoolize", true
	end

	def configure(myconf = nil)
		unless File.executable?("configure")
			raise Error::Package.new("missing configure file")
		end

		conf =  %Q{ --build=#{_CHOST} --host=#{_CHOST}}
		conf << %Q{ --prefix="#{_PREFIX}"}
		conf << %Q{ --sysconfdir="#{_ROOT}/etc"}
		conf << %Q{ --libdir="#{_PREFIX}/lib"}
		conf << %Q{ --includedir="#{_PREFIX}/include"}
		conf << %Q{ --datadir="#{_PREFIX}/share"}
		conf << %Q{ --mandir="#{_PREFIX}/share/man"}
		conf << %Q{ --infodir="#{_PREFIX}/share/info"}
		conf << %Q{ --localstatedir="#{_PREFIX}/var/lib"}

		retval = Util.run_v "./configure #{conf} #{myconf}", STDOUT
		if (retval != 0)
			if File.exist?("config.log")
				puts
				puts "!!! Check configuration log file:"
				puts "!!! #{Dir.pwd}/config.log"
			end
			raise Error::Package.new("configuration error")
		end
	end

	def opt_with(*flags)
		return " --with-#{flags.join(" --with-")}"
	end

	def opt_without(*flags)
		return " --without-#{flags.join(" --without-")}"
	end

	def opt_enable(*flags)
		return " --enable-#{flags.join(" --enable-")}"
	end

	def opt_disable(*flags)
		return " --disable-#{flags.join(" --disable-")}"
	end

	def platform?(platform)
		case platform
		when Enum::Value
			return Config._PLATFORM.is?(platform)
		when String
			return platform == Config._PLATFORM.name
		when Symbol
			return platform.to_s == Config._PLATFORM.name
		else
			raise TypeError
		end
	end

	def release?(release)
		case release
		when Enum::Value
			return Config._RELEASE.is?(release)
		when String
			return release =~ Config._RELEASE.nick
		when Symbol
			return release.to_s =~ Config._RELEASE.nick
		else
			raise TypeError
		end
	end

	def make(options = nil)
		retval = Util.run_v "make #{_MAKEFLAGS} #{options}", STDOUT
		raise Error::Package.new("make error") if retval != 0
	end

	def make_install(options = nil)
		conf =  %Q{ prefix="#{_DESTDIR}/#{_PREFIX}"}
		conf << %Q{ sysconfdir="#{_DESTDIR}/#{_ROOT}/etc"}
		conf << %Q{ libdir="#{_DESTDIR}/#{_PREFIX}/lib"}
		conf << %Q{ includedir="#{_DESTDIR}/#{_PREFIX}/include"}
		conf << %Q{ datadir="#{_DESTDIR}/#{_PREFIX}/share"}
		conf << %Q{ mandir="#{_DESTDIR}/#{_PREFIX}/share/man"}
		conf << %Q{ infodir="#{_DESTDIR}/#{_PREFIX}/share/info"}
		conf << %Q{ localstatedir="#{_DESTDIR}/#{_PREFIX}/var/lib"}

		retval = Util.run_v "make #{conf} #{options} install", STDOUT
		raise Error::Package.new("make install error") if retval != 0
	end

	def exec(command)
		retval = Util.run command, STDOUT
		raise Error::Package.new("exec failed") if retval != 0
	end

	def exec_r(command)
		retval = Util.run command
		raise Error::Package.new("exec failed") if $? != 0
		return retval
	end
	alias :cmd_redir :exec_r

	def exec_v(command, styled = false)
		if (styled)
			puts ">>> Running #{command}"
			retval = Util.run command, STDOUT
		else
			retval = Util.run_v command, STDOUT
		end
		raise Error::Package.new("exec failed") if retval != 0
	end
	alias :cmd :exec_v

	def sed(input, output, *cmds)
		cmd = "sed -e '#{cmds.join("' -e '")}' '#{input}' > '#{output}'"
		retval = Util.run cmd, STDOUT
		raise Error::Package.new("sed failed") if retval != 0
	end

	def sed_i(file, *cmds)
		cmd = "sed -i -e '#{cmds.join("' -e '")}' '#{file}'"
		retval = Util.run cmd, STDOUT
		raise Error::Package.new("sed failed") if retval != 0
	end

	def http_download(file, url, depth = 0)
		raise Error::Package.new("HTTP redirect too deep") if depth > 10

		if (depth == 0)
			puts ">>> Downloading #{url} => #{File.basename(file)}"
		else
			puts ">>> Redirected to #{url}"
		end

		uri = URI.parse(url)
		response = Net::HTTP.get_response(uri)
		case response
		when Net::HTTPSuccess
			File.open(file, "w") do |io|
				io.write response.body
			end
		when Net::HTTPRedirection
			http_download(file, response["location"], depth + 1)
		else
			raise Error::Package.new("HTTP download failed")
		end
	end

	def install_bin(files)
		bindir = "#{_DESTDIR}/#{_PREFIX}/bin"

		mkdir_p(bindir) unless File.directory?(bindir)
		files.each do |file|
			unless (File.exist?(file))
				raise Error::Package.new("missing file to install: #{file}")
			end

			cmd = %Q{install -m755 "#{file}" "#{bindir}"}
			retval = Util.run_v cmd, STDOUT
			raise Error::Package.new("install failed") if retval != 0
		end
	end

	def install_man(files)
		mandir = "#{_DESTDIR}/#{_PREFIX}/share/man"

		files.each do |file|
			unless (File.exist?(file))
				raise Error::Package.new("missing file to install: #{file}")
			end

			# extract section from file extension
			section = File.extname(file)
			section.slice!(0)

			if (section =~ /^[0-9n](f|p|pm)?$/)
				dir = "#{mandir}/man#{section}"
				mkdir_p(dir) unless File.directory?(dir)

				cmd = %Q{install -m0644 "#{file}" "#{dir}"}
				retval = Util.run_v cmd, STDOUT
				raise Error::Package.new("install failed") if retval != 0
			else
				raise Error::Package.new("invalid manual section: #{file}")
			end
		end
	end

	def cd(directory)
		Dir.chdir(directory)
	end

	def rm(list)
		FileUtils.rm(list)
	end

	def rm_rf(list)
		FileUtils.rm_rf(list)
	end

	def cp(src, dest)
		FileUtils.cp(src, dest)
	end

	def cp_r(src, dest)
		FileUtils.cp_r(src, dest)
	end

	def mkdir(dir)
		FileUtils.mkdir(dir)
	end

	def mkdir_p(dir)
		FileUtils.mkdir_p(dir)
	end

	def touch(list)
		FileUtils.touch(list)
	end
end

end # module Devball


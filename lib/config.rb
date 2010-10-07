require 'lib/error'
require 'lib/enums'
require 'lib/util'
require 'lib/set'

module Devball
module Base

class Config
	class << self
		# compilation properties that can be overwritten
		def _CHOST; const_get(:CHOST) if const_defined?(:CHOST); end
		def _CFLAGS; const_get(:CFLAGS) if const_defined?(:CFLAGS); end
		def _CXXFLAGS; const_get(:CXXFLAGS) if const_defined?(:CXXFLAGS); end
		def _LDFLAGS; const_get(:LDFLAGS) if const_defined?(:LDFLAGS); end
		def _MAKEFLAGS; const_get(:MAKEFLAGS) if const_defined?(:MAKEFLAGS); end

		# location properties that can be overwritten
		def _ROOT; const_defined?(:ROOT) ? const_get(:ROOT) : @@ROOT; end
		def _PREFIX; const_defined?(:PREFIX) ? const_get(:PREFIX) : @@PREFIX; end
		def _SPECS; const_defined?(:SPECS) ? const_get(:SPECS) : @@SPECS; end
		def _FILES; const_defined?(:FILES) ? const_get(:FILES) : @@FILES; end
		def _PATCHES; const_defined?(:PATCHES) ? const_get(:PATCHES) : @@PATCHES; end
		def _TMP; const_defined?(:TMP) ? const_get(:TMP) : @@TMP; end
		def _DB; const_defined?(:DB) ? const_get(:DB) : @@DB; end
		def _DISTFILES; const_defined?(:DISTFILES) ? const_get(:DISTFILES) : @@DISTFILES; end

		# read only properties
		def _ARCH; @@ARCH; end
		def _PLATFORM; @@PLATFORM; end
		def _RELEASE; @@RELEASE; end
		def _CONF; @@CONF; end

		# properties that are merged
		def _FEATURES; @@FEATURES; end
		def _BEHAVIOUR; @@BEHAVIOUR; end
	end

	def Config.init(klass)
		# paths
		@@ROOT = "/"                     # install root
		@@PREFIX = "/usr/local"          # install prefix (inside root)
		@@SPECS = "/usr/specs"           # spec files location
		@@FILES = "/usr/specs/files"     # source files location
		@@PATCHES = "/usr/specs/patches" # patches files location
		@@DISTFILES = "/var/tmp/devball" # distfiles download directory
		@@TMP = "/var/tmp/devball"       # build temporary directory
		@@DB = "/var/lib/devball"        # package management database

		# default features
		@@FEATURES = ""
		@@features = {}

		# default behaviour
		@@BEHAVIOUR = "collisions"
		@@behaviour = {}

		# system properties
		@@ARCH = nil
		@@PLATFORM = nil
		@@RELEASE = nil

		# fatal config error
		@@fatal = false

		# setup arch
		@@ARCH = case Util.run("uname -m")[0]
		when "x86", /^i[3456]86$/
			Arch::X86
		when "x86_64"
			Arch::X86_64
		else
			raise Error::Detect.new(Arch.class_name)
		end

		# setup platform
		@@PLATFORM = case Util.run("uname -s")[0]
		when "Linux"
			Platform::Linux
		when "Darwin"
			Platform::Darwin
		else
			raise Error::Detect.new(Platform.class_name)
		end

		# setup release
		_RELEASE = Util.run("uname -r")[0]
		@@RELEASE = Release.get_nick_match(_RELEASE)
		@@RELEASE = @@RELEASE.clone_with_data(_RELEASE)

		# load config
		@@CONF = nil

		_CONFDIRS = [
			"/etc/devball",
			Dir.pwd,
		]

		_CONFFILES = [
			"config-#{@@PLATFORM}-#{@@RELEASE}.rb",
			"config-#{@@PLATFORM}-#{@@ARCH}.rb",
			"config-#{@@PLATFORM}.rb",
			"config.rb",
		]

		# scan all possible locations
		_CONFDIRS.each do |dir|
			_CONFFILES.each do |location|
				next unless File.exist?("#{dir}/#{location}")
				@@CONF = "#{dir}/#{location}"
				break
			end
			break unless @@CONF.nil?
		end

		# check if config file exist
		if @@CONF.nil?
			message = "missing config, tried names:\n\t-> "
			message << _CONFFILES.join("\n\t-> ")
			raise Error::Config.new(message)
		end

		# load config file
		begin
			class_eval(File.open(@@CONF).read, @@CONF)
		rescue
			raise Error::Config.new("#{$@[0]}: #{$!.message}")
		end

		# merge features
		if (const_defined?(:FEATURES))
			@@FEATURES << " " << const_get(:FEATURES)
		end

		# process config and env features
		init_features(@@FEATURES)
		init_features(ENV["FEATURES"]) unless ENV["FEATURES"].nil?

		# merge behaviour
		if (const_defined?(:BEHAVIOUR))
			@@BEHAVIOUR << " " << const_get(:BEHAVIOUR)
		end

		# process config and env behaviour
		init_behaviour(@@BEHAVIOUR)
		init_behaviour(ENV["BEHAVIOUR"]) unless ENV["BEHAVIOUR"].nil?

		# setup compilation flags
		const_set(:CFLAGS, "") unless const_defined?(:CFLAGS)
		const_set(:CXXFLAGS, "") unless const_defined?(:CXXFLAGS)
		const_set(:LDFLAGS, "") unless const_defined?(:LDFLAGS)
		const_set(:MAKEFLAGS, "") unless const_defined?(:MAKEFLAGS)

		# setup some variables for _PREFIX
		unless feature?(:pure)
			# prefer utilities from _PREFIX
			ENV["PATH"] = "#{_PREFIX}/bin:#{ENV["PATH"]}"

			# setup some flags for _PREFIX
			_CFLAGS = remove_const(:CFLAGS)
			const_set(:CFLAGS, %Q{-I#{_PREFIX}/include #{_CFLAGS}})
			_CXXFLAGS = remove_const(:CXXFLAGS)
			const_set(:CXXFLAGS, %Q{-I#{_PREFIX}/include #{_CXXFLAGS}})
			_LDFLAGS = remove_const(:LDFLAGS)
			const_set(:LDFLAGS, %Q{-L#{_PREFIX}/lib #{_LDFLAGS}})
		end

		###
		# process WARNINGS
		###

		# probe umask
		if (File.umask == 0)
			STDERR.puts "WARNING: Detected 0000 umask, setting to 0022"
			File.umask(0022)
		end

		# check basic write permissions
		[:_DB, :_ROOT, :_PREFIX].each do |name|
			unless (Util.writable_p?(send(name)))
				@@fatal = true
				STDERR.puts "WARNING: No write permissions to Config.#{name}!"
			end
		end unless behaviour?(:spec)

		if (Process.uid == 0)
			@@fatal = true unless behaviour?(:superuser)
			STDERR.puts "WARNING: Running as superuser!"
		end unless behaviour?(:spec)
	end
	private_class_method :init

	def Config.init_features(names)
		names.split.each do |name|
			if (name[0] == ?-)
				name.slice!(0)
				@@features[name.to_sym] = false
			else
				@@features[name.to_sym] = true
			end
		end
	end
	private_class_method :init_features

	def Config.init_behaviour(names)
		names.split.each do |name|
			if (name[0] == ?-)
				name.slice!(0)
				@@behaviour[name.to_sym] = false
			else
				@@behaviour[name.to_sym] = true
			end
		end
	end
	private_class_method :init_behaviour

	def Config.feature?(name)
		return @@features[name.to_sym]
	end

	def Config.behaviour?(name)
		return @@behaviour[name.to_sym]
	end

	def Config.fatal?
		return @@fatal
	end
end

end # module Base

# load configuration
class Config < Base::Config
	init(self)
end

end # module Devball


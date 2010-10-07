require 'lib/package/contents'
require 'lib/package/features'
require 'lib/package/default'
require 'lib/package/attrs'
require 'lib/package/util'
require 'lib/error'
require 'lib/set'
require 'ftools'
require 'find'

module Devball

class Package
	# basic properties
	attr_reader :_SPEC, :_PACKAGE, :_NAME, :_VERSION

	# some destinations
	attr_reader :_TEMPDIR  # temporary directory
	attr_reader :_DESTDIR  # temporary install directory
	attr_reader :_WORKDIR  # work directory
	attr_reader :_BUILDDIR # temprorary build dir
	attr_reader :_FILESDIR
	attr_reader :_PATCHESDIR

	# properties to setup
	attr_reader :_DEPENDENCIES # []
	attr_reader :_URLS         # {}
	attr_reader :_FILES        # []
	attr_reader :_PATCHES      # []
	attr_reader :_SRCDIR       # _WORKDIR/_P
	attr_reader :_FEATURES     # ""

	# compiler flags
	attr_reader :_CHOST
	attr_reader :_CFLAGS, :_CXXFLAGS, :_LDFLAGS
	attr_reader :_MAKEFLAGS

	# aliases for properties
	alias :_P :_PACKAGE
	alias :_PN :_NAME
	alias :_PV :_VERSION
	alias :_T :_TEMPDIR
	alias :_D :_DESTDIR
	alias :_S :_SRCDIR

	# static attributes
	def _ROOT; Config._ROOT; end              # root of installation
	def _PREFIX; Config._PREFIX; end          # prefix for installation (should be inside _ROOT)
	def _FILESDIR; Config._FILES; end         # directory with all package files
	def _SPECSDIR; Config._SPECS; end         # directory with all specs files
	def _PATCHESDIR; Config._PATCHES; end     # directory with all patches files
	def _DISTFILESDIR; Config._DISTFILES; end # directory to download files

	# sysinfo attributes
	def _ARCH; Config._ARCH; end
	def _PLATFORM; Config._PLATFORM; end
	def _RELEASE; Config._RELEASE; end

	def initialize(path)
		filename = File.basename(path)
		atom = Atom.parse_name(filename)

		# import some basic properties
		@_SPEC = filename
		@_NAME, @_VERSION = atom
		@_PACKAGE = "#{@_NAME}-#{@_VERSION}"

		# setup basic directories
		@_BUILDDIR = "#{Config._TMP}/#{_PACKAGE}"
		@_WORKDIR = "#{Config._TMP}/#{_PACKAGE}/work"
		@_DESTDIR = "#{Config._TMP}/#{_PACKAGE}/image"
		@_TEMPDIR = "#{Config._TMP}/#{_PACKAGE}/temp"

		# prepare settable variables
		@_DEPENDENCIES = []
		@_URLS = {}
		@_FILES = []
		@_PATCHES = []
		@_FEATURES = ""
		@_SRCDIR = ""

		# inherit from file name
		inherit atom[2] if atom[2]

		# evaluate package
		instance_eval File.open(path).read, filename

		# update variables
		@_SRCDIR = "#{@_WORKDIR}/#{@_PACKAGE}" if @_SRCDIR.empty?
		initialize_features

		# setup object id
		@unique_id = @_SPEC.hash
	end

	def initialize_run_action
		# basic settable environment variables
		@_CHOST = Config._CHOST
		@_CFLAGS = Config._CFLAGS
		@_CXXFLAGS = Config._CXXFLAGS
		@_LDFLAGS = Config._LDFLAGS
		@_MAKEFLAGS = Config._MAKEFLAGS

		# setup basic environment variables
		ENV["CFLAGS"] = _CFLAGS
		ENV["CXXFLAGS"] = _CXXFLAGS
		ENV["LDFLAGS"] = _LDFLAGS
	end

	def initialize_features
		return if (_FEATURES.kind_of?(Array))
		@_FEATURES = Features.parse(_FEATURES)
	end

	def inspect
		"\#<#{self.class} #{@_SPEC}>"
	end

	def to_s
		if (@_FEATURES.empty?)
			@_PACKAGE
		else
			"#{@_PACKAGE} [#{@_FEATURES}]"
		end
	end

	def hash
		@unique_id
	end

	def ==(other)
		@unique_id == other.hash
	end
	alias :eql? :==

	def run_action(action, options = {})
		# additional init to limit Package.new
		initialize_run_action

		case action
		when :install
			# check if we are reinstalling/updating
			location_t = Specs.locate_db_name(_NAME)

			if (location_t.nil?)
				puts ">>> Installing #{_SPEC}"
			elsif (_VERSION >= location_t[1])
				puts ">>> Updating #{location_t[0]} => #{_SPEC}"
				db_spec = location_t[0]
			else
				puts ">>> Downgrading #{location_t[0]} => #{_SPEC}"
				db_spec = location_t[0]
			end

			# clean old _BUILDDIR
			rm_rf(_BUILDDIR) if File.directory?(_BUILDDIR)

			# prepare environment
			mkdir_p(_WORKDIR)
			mkdir_p(_DESTDIR)
			mkdir_p(_TEMPDIR)

			# package configuration
			run_action_phase :pkg_config, _WORKDIR

			# package compilation
			run_action_phase :src_fetch, _WORKDIR
			run_action_phase :src_unpack, _WORKDIR
			run_action_phase :src_prepare, _SRCDIR
			run_action_phase :src_configure, _SRCDIR
			run_action_phase :src_compile, _SRCDIR
			run_action_phase :src_install, _SRCDIR

			# package installation/reinstallation
			run_action_phase :pkg_preinstall, _SRCDIR
			contents = run_image_install _DESTDIR, db_spec
			run_action_phase :pkg_postinstall, _SRCDIR

			# remove old entry from database
			rm_rf("#{Config._DB}/#{db_spec}") unless db_spec.nil?

			# package config locations
			db_dir = "#{Config._DB}/#{_SPEC}"
			db_spec = "#{db_dir}/#{_SPEC}"
			db_CONTENTS = "#{db_dir}/CONTENTS"
			db_FEATURES = "#{db_dir}/FEATURES"

			# create package directory
			mkdir_p(db_dir)

			# store various properties
			File.open(db_CONTENTS, "w").write contents
			File.copy("#{Config._SPECS}/#{_SPEC}", db_spec)
			File.open(db_FEATURES, "w").write _FEATURES

			# clean _BUILDDIR
			rm_rf(_BUILDDIR)
		when :uninstall
			puts ">>> Uninstalling #{_SPEC}"

			# package uninstall
			run_action_phase :pkg_preuninstall
			contents = run_image_uninstall
			run_action_phase :pkg_postuninstall

			# package config locations
			db_dir = "#{Config._DB}/#{_SPEC}"

			# clean db entry
			rm_rf(db_dir)
		else
			raise Error::Action.new(action)
		end
	end

	def run_action_phase(phase, workdir = nil)
		if (respond_to?(phase))
			puts ">>> Phase #{phase}"

			# move to package workdir
			Dir.chdir(workdir) unless workdir.nil?

			# execute phase
			send phase
		else
			puts ">>> Phase #{phase} skipped"
		end
	end
	private :run_action_phase

	def run_image_install(workdir, db_pkg)
		puts ">>> Installing image"

		# move to image workdir
		Dir.chdir(workdir)

		# check if image is there
		unless File.directory?(".#{_ROOT}")
			return Contents.new
		end

		# check whether we reinstall package
		unless (db_pkg.nil?)
			reinstall = true
			files = Contents.read_to_set(db_pkg)
		else
			reinstall = false
			files = Set.new
		end

		# enter relative _ROOT inside image
		Dir.chdir(".#{_ROOT}")

		# collision detection
		if (Config.behaviour?(:collisions))
			puts ">>> Detecting image collisions"
			Find.find(".") do |src|
				dest = File.expand_path("#{_ROOT}/#{src}")

				if (File.exist?(dest))
					# existing file is directory or comes from old version
					next if files.key?(dest) || File.directory?(dest)
					raise Error::Package.new("collision detected: #{dest}")
				end
			end
		end

		puts ">>> Installing image files"
		contents = Contents.new
		Find.find(".") do |src|
			dest = File.expand_path("#{_ROOT}/#{src}")
			type = run_image_file_install(src, dest)

			# store list of files
			contents << Contents::Entry.new(type, dest)

			# remove from old files
			files.delete(dest)
		end

		# remove stale files
		if reinstall
			puts ">>> Safe old image removal"

			# extract correct order of files
			files = files.keys
			files.sort!
			files.reverse!

			# remove stale files
			files.each do |path|
				run_image_file_uninstall(path)
			end
		end

		# return contents
		contents
	end
	private :run_image_install

	def run_image_file_install(src, dest)

		# perform install action
		type = if File.symlink?(src)
			exist = File.symlink?(dest) || File.exist?(dest)
			File.delete(dest) if exist
			File.symlink(File.readlink(src), dest)
			:sym
		elsif File.file?(src)
			exist = File.exist?(dest)
			File.delete(dest) if exist
			File.copy(src, dest)
			:obj
		elsif File.directory?(src)
			exist = File.exist?(dest)
			Dir.mkdir(dest) unless exist
			:dir
		else
			raise Error::Filetype.new(src)
		end

		puts "#{exist ? "   " : "+++"} #{dest}"
		return type
	end
	private :run_image_file_install

	def run_image_uninstall()
		puts ">>> Uninstalling image"

		# locate image files
		files = Contents.read(_SPEC)

		# correct the order of files
		files.reverse!

		# remove stale files
		files.each do |path|
			run_image_file_uninstall(path)
		end
	end
	private :run_image_uninstall

	def run_image_file_uninstall(file)
		status = if File.file?(file) || File.symlink?(file)
			File.delete(file)
			"---"
		elsif File.directory?(file)
			begin
				Dir.rmdir(file)
				"---"
			rescue Errno::ENOTEMPTY
				"   "
			rescue Errno::EACCES
				"!!!"
			end
		else
			"!!!"
		end

		puts "#{status} #{file}"
	end
	private :run_image_file_uninstall

	def inherit(ext)
		source = "ext/#{ext}.rb"
		path = "#{Config._SPECS}/#{source}"
		instance_eval File.open(path).read, source
	end
	private :inherit

	def undef_phase(phase)
		instance_eval "undef :#{phase}" if respond_to?(phase)
	end
end

end # module Devball


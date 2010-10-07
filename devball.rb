#!/usr/bin/env ruby

# setup LOAD_PATHS for devball
$LOAD_PATH << File.dirname(__FILE__)

# load and initialize
begin
	require 'lib/config'
	require 'lib/options'
	require 'lib/specs'
	require 'lib/bench'
rescue OptionParser::ParseError, Devball::Error::Devball
	puts "#{$!} (#{$!.class})"
	exit
end

module Devball

begin
	# handle simple actions
	case Options.action
	when :help, :nil
	when :info
		# generate debug information
		puts Util.run("gcc --version")[0]
		puts Util.run("bash --version")[0]
		puts Util.run("ruby --version")[0]
		puts "=" * 80
		puts "Config._ARCH = #{Config._ARCH}"
		puts "Config._PLATFORM = #{Config._PLATFORM}"
		puts "Config._RELEASE = #{Config._RELEASE}"
		puts "=" * 80
		puts "_CHOST = #{Config._CHOST}"
		puts "_CFLAGS = #{Config._CFLAGS}"
		puts "_CXXFLAGS = #{Config._CXXFLAGS}"
		puts "_LDFLAGS = #{Config._LDFLAGS}"
		puts "_MAKEFLAGS = #{Config._MAKEFLAGS}"
		puts "=" * 80
		puts "Config._DB = #{Config._DB}"
		puts "Config._SPECS = #{Config._SPECS}"
		puts "Config._ROOT = #{Config._ROOT}"
		puts "Config._PREFIX = #{Config._PREFIX}"
		puts "Config._FEATURES = #{Config._FEATURES}"
		puts "Config._BEHAVIOUR = #{Config._BEHAVIOUR}"
	else
		# check for fatal config error
		if (Config.fatal?)
			STDERR.puts "FATAL: Non-recoverable warning for selected option"
			exit
		end

		# initialize spec files
		Specs.init
	end

	# handle complex actions
	case Options.action
	when :list
		# list all installed specs
		puts Specs.list_db(Options.target)

	when :owner
		# list all specs that own file
		puts Specs.list_db_owner(Options.target)

	when :install
		# prepare parameters
		location = Specs.locate(Options.target)
		options = {
			:pretend => Options.pretend,
			:force => Options.force,
			:world => Options.world
		}

		# run installation
		Specs.install(location, options)

	when :uninstall
		# prepare parameters
		location_t = Specs.locate_db(Options.target)
		options = {
		}

		# run installation
		Specs.uninstall(location_t[0], options)

	end
rescue Error::Devball
	puts "#{$!} (#{$!.class})"
end

Bench.stats

end # module Devball


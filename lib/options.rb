require 'optparse'

module Devball
module Base

class Options
	VERSION = 0.1

	class << self
		def action; @@action; end
		def target; @@target; end
		def bench; @@bench; end
		def pretend; @@pretend; end
		def force; @@force; end
		def world; @@world; end
	end

	def Options.init(mode, args)
		@@action = nil
		@@target = nil
		@@bench = false
		@@pretend = false
		@@force = false
		@@world = true

		case mode
		when :app
			parser = OptionParser.new do |opts|
				opts.banner = "Usage: devball.rb [options]"
				opts.separator ""
				opts.separator "Actions:"

				opts.on("-i", "--install PKG", String, "Install package") do |pkg|
					@@action = :install
					@@target = pkg
				end

				opts.on("-u", "--uninstall PKG", String, "Uninstall package") do |pkg|
					@@action = :uninstall
					@@target = pkg
				end

				opts.on("--list", "List installed packages") do
					@@action = :list
				end

				opts.on("--list-contents PKG", String, "List installed PKG contents") do |pkg|
					@@action = :list
					@@target = pkg
				end

				opts.on("-o", "--owner FILE", String, "Display owner of the file") do |file|
					@@action = :owner
					@@target = file
				end

				opts.on("--info", "Display system information") do
					@@action = :info
				end

				opts.on("--bench", "Benchmark certain functions execution") do
					@@bench = true
				end

				opts.on("-1", "--preserve-world", "Don't modify world file") do
					@@world = false
				end

				opts.on("-f", "--force", "Force action") do
					@@force = true
				end

				opts.on("-p", "--pretend", "Only pretend action") do
					@@pretend = true
				end

				opts.on("-h", "--help", "Show this message") do
					@@action = :help
					puts opts.help
				end

				opts.on("-V", "--version", "Show version") do
					puts VERSION
				end
			end

			# parse provided options
			parser.parse!(args)

			if (@@action.nil?)
				STDERR.puts "WARNING: Missing action, try --help"
			end
		when :spec
			parser = OptionParser.new do |opts|
				opts.on("--bench") do
					@@bench = true
				end
			end

			# parse provided options
			parser.parse!(args)
		end
	end
end

end # module Base

class Options < Base::Options
	$0.index("spec.rb").nil? ?
		init(:app, ARGV) : init(:spec, ARGV)
end

end # module Devball


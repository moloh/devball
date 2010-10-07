#!/usr/bin/env ruby

require 'rubygems'
require 'spec/runner/formatter/specdoc_formatter'
require 'spec'

module Spec; module Runner; module Formatter
	class DevballFormatter < BaseTextFormatter
		def example_group_started(example_group)
			output.puts example_group.description
			output.flush
		end

		def example_started(example)
			@timestamp = Time.new.to_f
		end

		def example_passed(example)
			message = "[%8.4f s] - #{example.description}" %
				[Time.new.to_f - @timestamp]
			output.puts green(message)
			output.flush
		end

		def example_failed(example, counter, failure)
			message = "[%8.4f s] - #{example.description} (FAILED - #{counter})" %
				[Time.new.to_f - @timestamp]
			output.puts red(message)
			output.flush
		end
	end
end; end; end

def spec_require(file)
	puts "Loading spec: #{file}"
	raise "Missing file: #{file}" unless File.exist?(file)
	require "#{Dir.pwd}/#{file}"
end

# load some basic modules
require 'lib/options'

# load tests
spec_require 'spec/version.rb'
spec_require 'spec/atom.rb'

# initialize benchmarking
require 'lib/bench'

Spec::Runner.options.parse_format "Spec::Runner::Formatter::DevballFormatter"
Spec::Runner.options.colour = true
Spec::Runner::run

# print benchmark stats
Devball::Bench.stats


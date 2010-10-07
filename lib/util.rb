
module Devball
module Util

class DEVNULL
	def DEVNULL.puts(*args); end
end

def Util.run(command, output = nil)
	unless block_given?
		unless output.nil?
			# return array of lines if no block provided
			IO.popen(command) do |io|
				until (line = io.gets).nil?
					output.puts line
				end
			end
			return $?
		else
			# return array of lines if no block provided
			lines = []
			IO.popen(command) do |io|
				until (line = io.gets).nil?
					lines << line
				end
			end
			return lines.each {|line| line.chomp!}
		end
	else
		# execute block on each line
		IO.popen(command) do |io|
			until (line = io.gets).nil?
				yield line
			end
		end
		return $?
	end
end

def Util.run_v(command, output = nil)
	# echo command
	unless output.nil?
		output.puts command
	else
		puts command
	end

	# execute command
	Util.run(command, output)
end

def Util.locate_file_in_dirs(file, *dirs)
	if (File.exist?(file))
		return file
	else
		dirs.each do |dir|
			path = "#{dir}/#{file}"
			return path if File.exist?(path)
		end
		raise Error::Package.new("missing file: #{file}")
	end
end

def Util.writable_p?(path)
	until (File.writable?(path))
		return false if File.exist?(path) || path.nil?
		path = File.dirname(path)
	end

	return true
end

end # module Util
end # module Devball


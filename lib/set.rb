
module Devball

class Set < Hash
	def initialize()
	end

	def read(filename)
		# clear set
		clear

		# load all items with removed newlines
		if (File.exist?(filename))
			File.open(filename).each do |line|
				self[line.chomp] = nil
			end
		end

		return self
	end

	def Set.read(filename)
		return Set.new.read(filename)
	end

	def write(filename)
		File.open(filename, "w+").write to_s
	end

	def to_s
		contents = ""
		each_key {|key| contents << "#{key}\n"}
		return contents
	end

	def <<(value)
		self[value] = nil
		return self
	end

	def >>(value)
		delete(value)
		return self
	end
end

end # module Devball


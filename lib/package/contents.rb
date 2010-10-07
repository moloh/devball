require 'lib/set'

module Devball

class Package
	class Contents < Array
		def Contents.read(name)
			contents = Contents.new
			File.open("#{Config._DB}/#{name}/CONTENTS").each do |line|
				contents << line.split[1]
			end
			return contents
		end

		def Contents.read_to_set(name)
			contents = Set.new
			File.open("#{Config._DB}/#{name}/CONTENTS").each do |line|
				contents[line.split[1]] = nil
			end
			return contents
		end

		def to_s
			contents = ""
			each {|entry| contents << entry.to_s}
			return contents
		end

		class Entry < Array
			def initialize(type, path)
				raise TypeError unless type.kind_of?(Symbol)
				raise TypeError unless path.kind_of?(String)

				self[0] = type
				self[1] = path
			end

			def to_s
				return "#{self[0]} #{self[1]}\n"
			end

			def ==(other)
				return false if self[0] != other[0]
				return false if self[1] != other[1]
				return true
			end
		end
	end
end

end # module Devball


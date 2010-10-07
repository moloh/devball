require 'lib/enum'

module Devball

class Match < Enum
	enum [:Equal, "="], [:GreaterEqual, ">="], [:Greater, ">"], [:LowerEqual, "<="], [:Lower, "<"]
end

class Suffix < Enum
	enum [:Alpha, "alpha"], [:Beta, "beta"], [:Pre, "pre"], [:Rc, "rc"], [:P, "p"]
end

class Arch < Enum
	enum :X86, :X86_64
end

class Platform < Enum
	enum :Linux, :Darwin
end

class Release < Enum
	enum [:Kernel_2_4, /^2.4/], [:Kernel_2_6, /^2.6/], [:Tiger, /^9.7.0$/], [:Leopard, /^9.8.0$/], [:SnowLeopard, /^10.[02].0$/], [:Other, /.*/]
end

end # module Devball


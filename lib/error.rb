require 'lib/enum'
require 'lib/util'

module Devball
module Error

class ECode < Enum
	enum \
		[:Internal, "internal error: %s"],
		[:Atom, "invalid atom: %s"],
		[:Match, "invalid atom, missing version match: %s"],
		[:Version, "invalid atom, corrupt version number: %s"],
		[:Detect, "environment detection error (%s)"],
		[:Spec, "invalid spec: %s"],
		[:Name, "invalid spec name: %s"],
		[:Missing, "missing spec: %s"],
		[:Ambiguous, "ambiguous specs: %s"],
		[:Dependencies, "dependencies error: %s"],
		[:Conflict, "dependencies conflict: %s"],
		[:Action, "unsupported action: %s"],
		[:Filetype, "unknown/not supported file type: %s"]
end

class Devball < StandardError
	def initialize(param, type = nil)
		super(type.nil? ? param : type.nick % [param])
	end
end

# helper method to define exception with message
def Error.define_class(klass, parent, enum)
	self.module_eval "class #{klass} < #{parent}
		def initialize(param, type = nil)
			super(param, type.nil? ? #{enum.nil? ? "nil" : enum.class_name} : type)
		end
	end"
end

Error.define_class(:Internal, :Devball, ECode::Internal)
Error.define_class(:Atom, :Devball, ECode::Atom)
Error.define_class(:Match, :Atom, ECode::Match)
Error.define_class(:Version, :Atom, ECode::Version)
Error.define_class(:Config, :Devball, nil)
Error.define_class(:Detect, :Devball, ECode::Detect)
Error.define_class(:Spec, :Devball, ECode::Spec)
Error.define_class(:Name, :Spec, ECode::Name)
Error.define_class(:Missing, :Spec, ECode::Missing)
Error.define_class(:Ambiguous, :Spec, ECode::Ambiguous)
Error.define_class(:Dependencies, :Spec, ECode::Dependencies)
Error.define_class(:Conflict, :Spec, ECode::Conflict)
Error.define_class(:Action, :Devball, ECode::Action)
Error.define_class(:Package, :Devball, nil)
Error.define_class(:Filetype, :Package, ECode::Filetype)

end # module Exception
end # module Devball


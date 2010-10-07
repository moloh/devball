require 'lib/atom'

module Devball

describe Atom do
	before(:all) do
		@atom = Atom.new("foo", Version.new("0"))
	end

	it "should provide interface" do
		@atom.should respond_to(:name)
		@atom.should respond_to(:version)
		@atom.should respond_to(:options)
	end

	describe :parse do
		example "=foo-2.1" do
			example_parse_is_correct(description, "foo", "2.1", Match::Equal)
		end

		example "=foo-bar-2.2" do
			example_parse_is_correct(description, "foo-bar", "2.2", Match::Equal)
		end

		example ">=foo-baz-0.1.1" do
			example_parse_is_correct(description, "foo-baz", "0.1.1", Match::GreaterEqual)
		end

		example "<maman-bar-0.1_rc1" do
			example_parse_is_correct(description, "maman-bar", "0.1_rc1", Match::Lower)
		end

		example ">maman-bar-2.1_rc8" do
			example_parse_is_correct(description, "maman-bar", "2.1_rc8", Match::Greater)
		end
	end

	describe :parse_name do
		example "foo-2.1.spec" do
			example_parse_name_is_correct(description, "foo", "2.1")
		end

		example "foo-bar-0.8_alpha.spec" do
			example_parse_name_is_correct(description, "foo-bar", "0.8_alpha")
		end

		example "foo-baz{man}-1.8.1.spec" do
			example_parse_name_is_correct(description, "foo-baz", "1.8.1", "man")
		end
	end

	def example_parse_is_correct(atom, name, version, match)
		_atom = Atom.parse(atom)

		_atom.name.should eql(name)
		_atom.version.should eql(Version.new(version))
		_atom.options[:match].should eql(match)
	end

	def example_parse_name_is_correct(atom, name, version, inherit = nil)
		_name, _version, _inherit = Atom.parse_name(atom)

		_name.should eql(name)
		_version.should eql(Version.new(version))
		_inherit.should eql(inherit)
	end
end

end # module Devball


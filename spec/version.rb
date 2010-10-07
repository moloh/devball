require 'lib/version'

module Devball

describe Version do
	before(:all) do
		@version = Version.new("0")
	end

	it "should provide interface" do
		@version.should respond_to(:parts)
		@version.should respond_to(:letter)
		@version.should respond_to(:suffix)
	end

	describe :<=> do
		example "0 < 0.9" do
			example_compare_is_correct(description, true)
		end

		example "1 < 0.9" do
			example_compare_is_correct(description, false)
		end

		example "0.8 < 0.9" do
			example_compare_is_correct(description, true)
		end

		example "0.8 < 0.8a" do
			example_compare_is_correct(description, true)
		end

		example "0.8a < 0.8d" do
			example_compare_is_correct(description, true)
		end

		example "0.8d < 0.8" do
			example_compare_is_correct(description, false)
		end

		example "0.8_alpha < 0.8" do
			example_compare_is_correct(description, true)
		end

		example "0.8_alpha < 0.8_beta" do
			example_compare_is_correct(description, true)
		end

		example "0.8_rc3 < 0.8_rc2" do
			example_compare_is_correct(description, false)
		end

		example "0.8_p < 0.8" do
			example_compare_is_correct(description, false)
		end

		example "0.8_p1 < 0.8_p" do
			example_compare_is_correct(description, false)
		end

		example "0 > 0.9" do
			example_compare_is_correct(description, false)
		end

		example "1 > 0.9" do
			example_compare_is_correct(description, true)
		end

		example "0.8 > 0.9" do
			example_compare_is_correct(description, false)
		end

		example "0.8a > 0.8" do
			example_compare_is_correct(description, true)
		end

		example "0.8a > 0.8d" do
			example_compare_is_correct(description, false)
		end

		example "0.8d > 0.8" do
			example_compare_is_correct(description, true)
		end

		example "0.8_alpha > 0.8" do
			example_compare_is_correct(description, false)
		end

		example "0.8 > 0.8_beta" do
			example_compare_is_correct(description, true)
		end

		example "0.8_alpha > 0.8_beta" do
			example_compare_is_correct(description, false)
		end

		example "0.8_rc3 > 0.8_rc2" do
			example_compare_is_correct(description, true)
		end

		example "0.8_p > 0.8" do
			example_compare_is_correct(description, true)
		end

		example "0.8_p1 > 0.8_p" do
			example_compare_is_correct(description, true)
		end
	end

	def example_compare_is_correct(description, outcome)
		_split = description.split(" ")
		_left = Version.new(_split[0])
		_operation = _split[1].to_sym
		_right = Version.new(_split[2])

		_left.send(_operation, _right).should eql(outcome)
	end
end

end # module Devball


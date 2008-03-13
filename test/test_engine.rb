$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'tictactoe'

class Test2 < Test::Unit::TestCase
	
	def test_not_null
		assert_not_nil TicTacToe.new.field, "new field must not be nil" 
  end
	
	def test_size_nine
		assert_equal 9, TicTacToe.new.field.length, "new field should have length 9"
  end
end

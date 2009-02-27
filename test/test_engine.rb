$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'tictactoe'

class Test2 < Test::Unit::TestCase
	
  def test_not_null
    assert_not_nil TicTacToe.new.field, "new field must not be nil" 
  end
	
  def test_size_nine
    assert_equal 3, TicTacToe.new.field[0].length, "checking field size"
    assert_equal 3, TicTacToe.new.field[1].length, "checking field size"
    assert_equal 3, TicTacToe.new.field[2].length, "checking field size"
    assert_equal nil, TicTacToe.new.field[3], "checking field size"
  end
end

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'tictactoe'

class AItest < Test::Unit::TestCase
  def test_dont_pick_occupied
    100.times do
      f = TicTacToe.new
      f.field[0][0].player = 1
      f.field[1][1].player = 2
      x, y = f.ki_get_move
      assert_equal 0, f.field[x][y].player, "ki chose occupied field"
    end
  end
end

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'

class AItest < Test::Unit::TestCase
  def test_dont_pick_occupied
		100.times do
			x = TicTacToe.new
			x.field[3] = 1
			x.field[1] = 2
			x = x.kiGetMove
			assert_not_equal 1, x, "ki chose occupied field"
			assert_not_equal 3, x, "ki chose occupied field"
		end
	end
end

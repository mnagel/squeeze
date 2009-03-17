$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'v_math'

class VMathTest < Test::Unit::TestCase
  def test_addition
    x = V2.new(0, 0)
    y = V2.new(1, 1)
    assert_equal x+y, y, "addition failed"
  end
end

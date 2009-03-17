#!/usr/bin/env ruby -wKU

=begin
    tictactoe - tic tac toe game
    Copyright (C) 2008, 2009 by Michael Nagel

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    $Id$

=end

# TODO document
# TODO add test code...
class V2
  attr_accessor :x, :y

  def initialize x=0, y=0
    @x, @y = x, y
  end

  def clone
    return V2.new(@x, @y)
  end

  def ==(v)
    @x == v.x and @y == v.y
  end

  def +(v)
    V2.new(@x + v.x, @y + v.y)
  end

  def -(v)
    V2.new(@x - v.x, @y - v.y)
  end

  def *(r)
    V2.new(r * @x, r * @y)
  end

  def dot(v)
    @x * v.x + @y * v.y
  end

  def alpha(v, cosined=false)
    cos = dot(v) / Math.sqrt(abs(true) * v.abs(true))
    cosined ? cos : Math.acos(cos) * 180 / Math::PI
  end

  def cross(v_right)
    throw "cross product not purposeful in 2d, you know"
  end

  def abs(squared=true)
    square = @x * @x + @y * @y
    squared ? square : Math.sqrt(square)
  end

  def unit
    fact = 1.0 / abs(false)
    V2.new(@x * fact, @y * fact)
  end

  def normal(left=true)
    left ? V2.new(-@y, @x) : V2.new(@y, -@x)
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end

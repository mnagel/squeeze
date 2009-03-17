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

def collide p1, p2, v1, v2, m1, m2
  10.times do puts end
  puts "doing collision: p1 #{p1}, p2 #{p2}, v1 #{v1}, v2 #{v2}, m1 #{m1}, m2 #{m2}"
  # normal and tangential directions
  normal     = p2 - p1
  puts "normal #{normal}"
  tangential = normal.normal
  puts "tangential #{tangential}"

  # split movement in normal/tangential component
  v1n = normal.unit.dot(v1)
  puts "v1n #{v1n}"
  v1t = tangential.unit.dot(v1)
  puts "v1n #{v1t}"

  v2n = normal.unit.dot(v2)
  puts "v1n #{v2n}"
  v2t = tangential.unit.dot(v2)
  puts "v1n #{v2t}"

  # calculate new normal components (primed ('))
  v1np = (v1n * (m1-m2) + 2 * m2 * v2n) / (m1 + m2)
  puts "v1np #{v1np}"
  v2np = (v2n * (m2-m1) + 2 * m1 * v1n) / (m1 + m2)
  puts "v2np #{v2np}"


  # add new normal * normal_direction to old tangential to get result
  res1 = (tangential.unit * v1t) + (normal.unit * v1np)
  res2 = (tangential.unit * v2t) + (normal.unit * v2np)

  puts "res1 #{res1}"
  puts "res1 #{res1}"

  return res1, res2
end
#!/usr/bin/env ruby -wKU

=begin
    v_math - mathematical/physical 2 dimensional vector class
    Copyright (C) 2009 by Michael Nagel

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

# V2 is a mathematical/physical 2 dimensional vector class
class V2
  attr_accessor :x, :y

  # initialize with given values, defaulting to zero
  def initialize x=0, y=0
    @x, @y = x, y
  end

  # return a new instance with identical values
  def clone
    return V2.new(@x, @y)
  end

  # check if instances math in all dimensions
  def ==(v)
    @x == v.x and @y == v.y
  end

  # return the sum as new instance
  def +(v)
    V2.new(@x + v.x, @y + v.y)
  end

  # return the difference as new instance
  def -(v)
    V2.new(@x - v.x, @y - v.y)
  end

  # return new instance multiplied by a scalar
  def *(r)
    V2.new(r * @x, r * @y)
  end

  # return the dot product of two instances
  def dot(v)
    @x * v.x + @y * v.y
  end

  # return the angle between to instances
  # iff cosined is false, return correct angle in degrees
  # iff cosined is true, return the cosine of that angle (this is slightly faster)
  def alpha(v, cosined=false)
    len = abs(true)
    cos = dot(v) / Math.sqrt(len * len)
    cosined ? cos : Math.acos(cos) * 180 / Math::PI
  end

  # cross product is undefined for 2d vectors right now and throws an exeption
  def cross(v)
    throw "cross product not purposeful in 2d, you know"
  end

  # returns the absolute value (length) of the vector
  # iff squared is false, return the correct length
  # iff squared is true, return the squared value thereof
  def abs(squared=true)
    square = @x * @x + @y * @y
    squared ? square : Math.sqrt(square)
  end

  # return new instance with an abs. length 1 pointing in the same direction
  def unit
    fact = 1.0 / abs(false)
    V2.new(@x * fact, @y * fact)
  end

  # return new instance orthogonal to the receiver
  # iff left is true, coordinate system is assumed to be left-handed
  # iff left is false, coordinate system is assumed to be right-handed
  def normal(left=true)
    left ? V2.new(-@y, @x) : V2.new(@y, -@x)
  end

  # return a properly formatted string representing this vector
  def to_s
    "(#{@x}, #{@y})"
  end
end

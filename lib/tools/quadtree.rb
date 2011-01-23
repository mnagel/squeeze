#!/usr/bin/env ruby -wKU

=begin
    quadtree - a quadtree for glgames
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

=end

# TODO integrate into games

$LOAD_PATH << './lib/' << './lib/tools/'
require 'v_math'

include Math

puts V2.new

module Payload

  #module Velocity
  def self.extend_object(o)
    super
    #o.instance_eval do @v = V.new end # sneak in the v AUTOMATICALLY...
  end

  #attr_accessor :v
  # TODO add "leafes i am in"

  attr_accessor :tl, :br
end

class String
  include Payload
end

class Quad

  attr_accessor :tl, :br, :subs, :data;
  # TODO add parent

  def leaf?
    @subs.length == 0
  end

  def initialize tl, br
    @tl, @br = tl, br
    @subs = []
    @data = []
  end

  def split
    return unless leaf?
    cx = (@tl.x + @br.x) / 2
    cy = (@tl.y + @br.y) / 2

    hw = V2.new(cx,0)
    hh = V2.new(0,cy)

    @subs << Quad.new(@tl      , @tl+hw+hh) # tl
    @subs << Quad.new(@tl+hw   , @br-hh   ) # tr
    @subs << Quad.new(@tl+hh   , @br-hw   ) # bl
    @subs << Quad.new(@tl+hw+hh, @br      ) # br

    @subs.each do |sub|
      @data.each do |data|
        sub.insert data
      end
    end
  end

  def insert data #, tl, br
    # check bounds
    if data.tl.x > @br.x or data.tl.y > @br.y or data.br.x < @tl.x or data.br.y < @tl.y
      return
    end

    @data << data
    @subs.each do |sub| sub.insert data end
  end

  # TODO check everything in file for <= instead of <
  def point_in_me px, py, me_tl, me_br
    px > me_tl.x and px < me_br.x and py > me_tl.y and py < me_br.y
  end

  def move data, val
    # TODO assert data is in this quad

    return unless leaf?

    changed = false


  end

  def list
    @data
  end

  def to_s rec=false
    s = "quad (#{@tl}:#{@br})"
    @data.each do |data| s += "\n#{data}@#{data.tl}:#{data.br}" end
    if rec
      s += "\n ::: subs ::: "
      @subs.each do |sub|
        s += "\n --- next sub ---"
        s += sub.to_s rec
      end
      s += "\n ::: end subs :::"
    end
    s
  end

end

tl = V2.new(0,0)
br = V2.new(100,100)

a = V2.new(10,10)
b = V2.new(20,20)
c = V2.new(30,30)
d = V2.new(60,40)
puts a, b, c

q = Quad.new(tl, br)
puts q

s1 = "hallo"
s1.tl = a
s1.br = a*2

s2 = "du"
s2.tl = b
s2.br = b+c

s3 = "123"
s3.tl = d
s3.br = d+a

s4 = "456"
s4.tl = d+a
s4.br = d+a+a

q.insert s1
q.insert s2
q.insert s3
puts q

puts "splitting"
q.split
q.insert s4
puts q.to_s true

#!/usr/bin/env ruby -wKU

=begin
    squeeze - a simple game.
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

# TODO further seperate Model, View, Controller

class BubbleModel < Entity
  attr_accessor :controller

#    include Velocity
#    include Gravity
#    include Bounded
#    include DoNotIntersect

  def initialize(x, y, size)
    super(x, y, size, size)

    extend(Velocity)
    extend(Gravity)
    extend(Bounded)
    extend(DoNotIntersect)

#        self.extend Rotating
#    @rotating = true
  end

#  def tick dt
#    super dt
#    puts "ticking bubble r #{@r}"
#  end
#
#  def tick
#    controller.view
#  end

#    def initialize(x, y, size)
#    super(x, y, size)
#
#  end

end

class BubbleView < Circle
  attr_accessor :controller



  def pos
    @controller.model.pos
  end

  def pos=val
    @controller.model.pos=val
  end

  def size
    @controller.model.size
  end

  def size=val
    @controller.model.size=val
  end

  def r
    @controller.model.r
  end

  def r=val
    @controller.model.r=val
  end

end

## TODO remove this class
#class TickSucker
#  def tick delta
#    puts STDERR.puts "sucking tick #{delta}"
#  end
#end

class BubbleController #< TickSucker
  def initialize x, y, size
    @model = BubbleModel.new(x, y, size)
    @model.controller = self
    @view = BubbleView.new(x, y, size)
    @view.controller = self
  end

#  def tick delta
#    @model.tick delta
#  end

  # TODO do not make them publicly available
  attr_accessor :model, :view;
end

# TODO make subclass so that good and evil are different! subclasses of one class
Bubble = BubbleController

class EvilBubbleController < BubbleController

end

EvilBubble = EvilBubbleController

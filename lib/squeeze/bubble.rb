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

=end

# TODO further seperate Model, View, Controller

class BubbleModelBase < Entity
  attr_accessor :controller

  def initialize(x, y, size)
    super(x, y, size, size)
  end
end

class BubbleModel < BubbleModelBase
  def initialize(x, y, size)
    super(x, y, size)

    extend(Velocity)
    extend(Gravity)
    extend(Bounded)
    extend(DoNotIntersect)
  end
end

class EvilBubbleModel < BubbleModelBase
  def initialize(x, y, size)
    super(x, y, size)

    extend(Velocity)
#    extend(Gravity)
    extend(Bounded)
    extend(DoNotIntersect)
  end
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

class BubbleController
  def initialize x, y, size
    @model = BubbleModel.new(x, y, size)
    @model.controller = self
    @view = BubbleView.new(x, y, size)
    @view.controller = self
  end

  # TODO do not make them publicly available
  attr_accessor :model, :view;
end

# TODO make subclass so that good and evil are different! subclasses of one class
Bubble = BubbleController

# FIXME copy&paste programming happens here...
class EvilBubbleController < BubbleController
  def initialize x, y, size
    @model = EvilBubbleModel.new(x, y, size)
    @model.controller = self
    @view = BubbleView.new(x, y, size)
    @view.controller = self
  end
end

EvilBubble = EvilBubbleController

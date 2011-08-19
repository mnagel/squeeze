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

class MouseModel < Entity
  attr_accessor :v, :gonna_spawn, :pict
  THRESHSTART = 1.2 # TODO make setting

  def reset_after_spawn
    @buff = 1
    if @size.x == Settings.mousedef
      puts "under thresh"
    end
  end

  def initialize x, y, size
    extend Rotating
    @rotating = true

    super x, y, size, size
    @v = Math::V2.new(0, 0)

    @shrinking = @growing = false
    @gonna_spawn = $tex[rand($tex.length)]
    @buff = 1
  end

    def shrinking=bool
    @shrinking = bool
  end

  def growing=bool
    @growing = bool
  end

  def render
    puts "panic"
  end

  def grow dsize
    dsize *= 0.01
    dsize += 1

    @buff *= dsize
    return if @buff < THRESHSTART

    return if @size.y < 30 and dsize < 0 # TODO re-ccheck
    return if @size.y > 1000 and dsize > 0
    dsize = -1 / dsize if dsize < 0
    @size.y *= dsize
    @size.x *= dsize
  end

    def tick dt
    super dt
    $engine.mouse.view.tick dt
    x = 0.1
    grow(+dt * x) if @growing and $engine.engine_running
    grow(-dt * x) if @shrinking and $engine.engine_running
  end
end

class MouseView < OpenGL2D

  attr_accessor :v, :gonna_spawn, :pict

  def initialize x, y, size
    super x, y, size, size
    extend(Rotating)

    @v = Math::V2.new(0, 0)
    @gcolors = @colors = ColorList.new(3) do Color.random(0, 0.8, 0, 0.7) end
    @rcolors = ColorList.new(3) do Color.random(0.8, 0, 0, 0.7) end

    oe = 1.3
    @green = Triangle.new(0, 0, oe, oe)
    @green.colors = @colors
    @pict = Square.new(0, 0, 1)

    a = 1.0
    @pict.colors = ColorList.new(4) do Color.new(a, a, a, 1.0) end

    @subs << @green << @pict

    @rotating = true
    @shrinking = @growing = false
    @gonna_spawn = $tex[rand($tex.length)]

    @pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end

  def pos
    $engine.mouse.model.pos
  end

  def pos=val
    $engine.mouse.model.pos=val
  end

  def size
    $engine.mouse.model.size
  end

  def size=val
    $engine.mouse.model.size=val
  end

  def r
    $engine.mouse.model.r
  end

  def r=val
    $engine.mouse.model.r=val
  end


  def tick dt
    super dt
    @pict.texture = @gonna_spawn

    coll = $engine.can_spawn_here($engine.mouse.model)
    if coll #.nil?
      @green.colors = @gcolors
    else
      @green.colors = @rcolors
    end
  end
end

class MouseController
  def initialize x, y, size
    @model = MouseModel.new(x, y, size)
    @view = MouseView.new(x, y, size)
  end

  # TODO do not make them publicly available
  attr_accessor :model, :view;
end

Mouse = MouseController

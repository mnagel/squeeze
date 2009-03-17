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

# TODO clean constants
$LOAD_PATH << './lib'

FONTFILE = "/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf"
INFOTEXT = <<EOT
    tictactoe - tic tac toe game
    Copyright (C) 2008, 2009 by Michael Nagel

    icons from buuf1.04.3 http://gnome-look.org/content/show.php?content=81153
    icons licensed under Creative Commons BY-NC-SA
EOT
WINDOWTITLE = "glfiller.rb by Michael Nagel"

def silently(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  result
end

silently do require "sdl" end
require "opengl"
require 'glbase'

require 'v_math'

# TODO move from graphics to backend model!
module Velocity
  def reinit2
    @v = V2.new
  end

  def invert
    @v *= -1
  end

    attr_accessor :v

  def tick dt
    super
    @pos.x += @v.x * dt
    @pos.y += @v.y * dt
  end
end

module Gravity
  def tick dt
    super
    @v.y += dt * 0.01 # axis is downwards # TODO check if this is indepent of screen size
  end
end

module Bounded

  @@bounce = 0.8

  def weaken
    @v.x *= @@bounce
    @v.y *= @@bounce
  end

  def tick dt
    super


    # TODO objects "hovering" the bottom freak out sometimes
    if @pos.x < 0
      @pos.x = -@pos.x
      @v.x = -@v.x
      weaken
    end

        if @pos.y < 0
      @pos.y = -@pos.y
      @v.y = -@v.y
      weaken
    end

    if @pos.x > XWINRES - @size.x
      @pos.x = (XWINRES - @size.x) - (@pos.x - (XWINRES - @size.x))
      @v.x = -@v.x
      weaken
    end

        if @pos.y > YWINRES - @size.y
      @pos.y = (YWINRES - @size.y) - (@pos.y - (YWINRES - @size.y))
      @v.y = -@v.y
      weaken
    end

  end
end

class Float
  def self.rand min, max
    return min + Kernel.rand(0) * (max - min)
  end
end

class Mouse < Entity
  include Rotating
  
  def initialize x, y, size, texture
    super x, y, size, size
    @colors = ColorList.new(3) do Color.random(0, 0.8, 0, 0.7) end

    @green = Triangle.new(0, 0, 1, 1)
    @green.colors = @colors
    @pict = Square.new(0, 0, 0.8)

    a = 1.0
    @pict.colors = ColorList.new(4) do Color.new(a, a, a, 1.0) end
    @pict.texture = texture

    @subs << @green
    @green.subs  << @pict
    
    @rotating = true
    @shrinking = @growing = false
  end

  def shrinking=bool
    @shrinking = bool
  end

  def growing=bool
    @growing = bool
  end

  def grow dsize
    dsize *= 0.01
    dsize += 1
    return if @size.y < 30 and dsize < 0
    return if @size.y > 1000 and dsize > 0
    dsize = -1 / dsize if dsize < 0
    @size.y *= dsize
    @size.x *= dsize
  end

  def tick dt
    super dt
    x = 1
    grow(+dt * x) if @growing
    grow(-dt * x) if @shrinking
  end
end

def collide? obj, obj2
          dx = obj.pos.x - obj2.pos.x
        dy = obj.pos.y - obj2.pos.y
        #puts "dx #{dx} -- dy #{dy}"
        dx *= dx
        dy *= dy
        dsq = dx + dy
        # for squares/circs
        sizes =  obj.size.x * obj.size.x + obj2.size.x * obj2.size.x #0.5 * (obj.w * obj2.w)
        return dsq < sizes
end

$score = 0
$crashes = 0
def draw_gl_scene dt
  define_screen 600, 600
  
  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

  @m.tick dt
  @m.render

  # TODO move from render to update
    #i = 1
    kkk = 0

  if $bla.length > 2
    (1..($bla.length-1)).each { |i|
      ((i+1)..($bla.length-1)).each { |j|
#    $bla.slice(1..-1).each_with_index { |obj,i|
#      $bla.slice((i+1)..-1).each_with_index { |obj2,j|
#
#      if i < j
obj = $bla[i]
obj2 = $bla[j]
      #puts "(#{i})(#{j}) checking #{obj}  and #{obj2} "
      kkk += 1


        if collide? obj, obj2 # TODO dont move them inside each other in the first place
#          puts "#{$crashes} (#{i})(#{j}) checking #{obj}  and #{obj2} crash!!!"
#          puts "sizes #{sizes} --- dsq #{dsq}"

          # TODO do correct bouncing here
          #$engine.timer.pause
          #obj.invert
          #obj.weaken
          #obj2.invert
          #obj2.weaken
          # FIXME this backtracking is an !!!EVIL!!! hack, dont move them in the first place!
          obj.pos -= obj.v * dt * 1.5
          obj2.pos -= obj2.v * dt * 1.5

          r1, r2 = collide(obj.pos, obj2.pos, obj.v, obj2.v, 1, 1)

          obj.v = r1
          obj2.v = r2

          $crashes += 1
        end



      }

    }
  end
  
  #puts "total of #{kkk} checks"


  $bla.each do |x|
    x.tick dt
    

    x.render
end
  $bla.first.set_text "rendering @#{$engine.timer.ticks_per_second}fps \n score: #{$score}" # TODO move fps into main engine
  $bla.first.render
end

def on_key_down key
  case key
  when SDL::Key::ESCAPE then
    $engine.kill!
  when 48 then # Zero
  when 97 then # A
    on_mouse_down(SDL::Mouse::BUTTON_MIDDLE, @m.pos.x, @m.pos.y)
  when 98 then # B
    $engine.timer.toggle
  when SDL::Key::SPACE then
    $bla = $bla.slice(0..0)
    $score = 0
  else
    puts key
  end
end

class Circle < Square
  def initialize(x, y, size)
    super x, y, size
    @texture = $tex[rand($tex.length)] #$p1
    @colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end
end

def on_mouse_down button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
    @m.shrinking = true
  when SDL::Mouse::BUTTON_LEFT then
    @m.growing = true
  when SDL::Mouse::BUTTON_MIDDLE then
    foo = Circle.new(x, y, @m.size.x)
    foo.extend(Velocity)
    foo.reinit2
    foo.extend(Gravity)
    foo.extend(Bounded)
    foo.v.x = Float.rand(-1,1)

    $bla << foo
    $score += (2 * foo.size.x *  2* foo.size.x * 3.14 / 4) / (XWINRES * YWINRES)
  end
end

def on_mouse_up button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
    @m.shrinking = false
  when SDL::Mouse::BUTTON_LEFT then
    @m.growing = false
  when SDL::Mouse::BUTTON_MIDDLE then
  end
end

def on_mouse_move x, y
  @m.pos.x = x
  @m.pos.y = y
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $engine.kill!
  elsif event.is_a?(SDL::Event2::KeyDown)
    on_key_down event.sym
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseButtonUp)
    on_mouse_up event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    on_mouse_move event.x, event.y
  end
end

class Engine
  def prepare
    $tex = []

    Dir.entries("gfx/filler").reject { |e| not e =~ /.*\.png/}.each { |fn|

    thef = "gfx/filler/#{fn}"
    #puts thef
    $tex << Texture.load_file(thef)

    }

    $p1 = Texture.load_file("gfx/a.png")
    $p2 = Texture.load_file("gfx/b.png")
    @m = Mouse.new(100, 100, 100, $p2)

    # TODO kill bla
    $bla = [Text.new(10, 10, 20, Color.new(255, 100, 255, 1.0), FONTFILE, "FPS GO HERE")]
    $bla.first.extend(TopLeftPositioning)

    $engine.window_title = WINDOWTITLE
  end
end

begin
  puts INFOTEXT
  $engine = Engine.new
  $engine.prepare
  $engine.run!
rescue => exc
  STDERR.puts "there was an error: #{exc.message}"
  STDERR.puts exc.backtrace
end

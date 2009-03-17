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

# TODO proper mouse picture

# TODO add monsters, make them harm

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


# TODO show "level up"
# TODO have multiple lives
# TODO show "you scored... " on gameover
# FIXME infinite growth in corners possible
# TODO make perfectly round graphics and use them...
# TODO for mouse use image of thing going to spawn...


# TODO give me a name
$bla = nil

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

class Float
  def self.rand min, max
    return min + Kernel.rand(0) * (max - min)
  end
end

class Mouse < Entity
  include Rotating

  attr_accessor :v
  
  def initialize x, y, size, texture
    super x, y, size, size
    @v = V2.new(0, 0)
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
    x = 0.1
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
  guess = 1 # 0.85 # there is some border around the images # TODO make this more correct
  sizes = ((obj.size.x + obj2.size.x) * guess) ** 2  #obj.size.x * obj.size.x + obj2.size.x * obj2.size.x #0.5 * (obj.w * obj2.w)
  return dsq < sizes
end

def get_collider who
  res = nil
  $thing_not_to_intersect.each { |thing|
    if thing != who
      res = thing if collide?(who, thing)
    end
  }
  return res
end

def update_world dt
  @m.tick dt

  $bla.each do |x|
    x.tick dt
  end
  
  $bla.first.set_text "rendering @#{$engine.timer.ticks_per_second}fps \n score: #{($score * 100).to_i}, ges: #{($scoreges * 100).to_i}" # TODO move fps into main engine
end

$score = 0
$scoreges = 0
$crashes = 0

def draw_gl_scene
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  define_screen 600, 600
  
  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

  @m.render


  $bla.each do |x|
    x.render
  end
  $bla.first.render
end

def reset2 score0=true

  if $bla.nil?
    $bla = [Text.new(10, 10, 20, Color.new(255, 100, 255, 1.0), FONTFILE, "FPS GO HERE")]
    $bla.first.extend(TopLeftPositioning)
  else
    $bla = $bla.slice(0..0)
  end
  $thing_not_to_intersect = []# [@m]
  5.times do |t|
    x = 100
    y = (t+1) * 83
    foo = Circle.new(x, y, $mousedef, $ene)
    foo.extend(Velocity)
    foo.reinit2
    #foo.extend(Gravity)
    foo.extend(Bounded)
    foo.extend(DoNotIntersect)
    foo.v.x = Float.rand(-1,1)
    foo.v.y = Float.rand(-1,1)
    $bla << foo
    $thing_not_to_intersect << foo

  end

  $score = 0
  $scoreges = 0 if score0
end

def on_key_down key
  case key
  when SDL::Key::ESCAPE then
    $engine.kill!
  when 48 then # Zero
    $SHOW_BOUNDING_BOXES = (not $SHOW_BOUNDING_BOXES)
  when 97 then # A
    on_mouse_down(SDL::Mouse::BUTTON_MIDDLE, @m.pos.x, @m.pos.y)
  when 98 then # B
    $engine.timer.toggle
  when SDL::Key::SPACE then
    reset2
  else
    puts key
  end
end

class Circle < Square
  def initialize(x, y, size, text=nil)
    super x, y, size
    @texture = text
    @texture = $tex[rand($tex.length)] if @texture.nil? #$p1
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
    $thing_not_to_intersect.each { |t|
      $engine.timer.pause
      puts "pos #{t.pos} -- size : #{t.size}"

    }
  end
end

def on_mouse_up button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
    @m.shrinking = false
  when SDL::Mouse::BUTTON_LEFT then

    # TODO let things have a mass...
    s =  @m.size.x
    foo = Circle.new(x, y, s)
    foo.extend(Velocity)
    foo.reinit2
    foo.extend(Gravity)
    foo.extend(Bounded)
    foo.extend(DoNotIntersect)
    foo.v.x = Float.rand(-1,1)
    foo.v.y = Float.rand(-1,1)
    #foo.extend(Rotating)
    #foo.r = rand(1000)
    # TODO dont allow creation in something else...

    $bla << foo
    $score += (2 * foo.size.x *  2* foo.size.x * 3.14 / 4) / (XWINRES * YWINRES)
    $scoreges += (2 * foo.size.x *  2* foo.size.x * 3.14 / 4) / (XWINRES * YWINRES)
    $thing_not_to_intersect << foo

    reset2(false) if $score > 0.5

    @m.growing = false
    @m.size = V2.new($mousedef, $mousedef)

    unless get_collider(foo).nil?
      reset2
    end

  when SDL::Mouse::BUTTON_MIDDLE then
  end
end

def on_mouse_move x, y
#  oldx = @m.pos.x
#  oldy = @m.pos.y
  @m.pos.x = x
  @m.pos.y = y
#  @m.v.x = (@m.pos.x - oldx) / 10
#  @m.v.y = (@m.pos.y - oldy) / 10
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


$mousedef = 40
class Engine
  def prepare
    $tex = []

    Dir.entries("gfx/filler").reject { |e| not e =~ /.*\.png/}.each { |fn|

      thef = "gfx/filler/#{fn}"
      #puts thef
      text = Texture.load_file(thef)
      $tex << text

      $ene = text if fn == "emblem-danger.png"

    }

    $p1 = Texture.load_file("gfx/a.png")
    $p2 = Texture.load_file("gfx/b.png")
    @m = Mouse.new(100, 100, $mousedef, $p2)

    # TODO kill bla
    reset2

    $engine.window_title = WINDOWTITLE
  end
end

# TODO put this somewhere better
def collide p1, p2, v1, v2, m1, m2
  # normal and tangential directions
  normal     = p2 - p1
  tangential = normal.normal

  # split movement in normal/tangential component
  v1n = normal.unit.dot(v1)
  v1t = tangential.unit.dot(v1)

  v2n = normal.unit.dot(v2)
  v2t = tangential.unit.dot(v2)

  # calculate new normal components (primed ('))
  v1np = (v1n * (m1-m2) + 2 * m2 * v2n) / (m1 + m2)
  v2np = (v2n * (m2-m1) + 2 * m1 * v1n) / (m1 + m2)

  # add new normal * normal_direction to old tangential to get result
  res1 = (tangential.unit * v1t) + (normal.unit * v1np)
  res2 = (tangential.unit * v2t) + (normal.unit * v2np)

  return res1, res2
end

# TODO move from graphics to backend model!
module Velocity
  def reinit2
    @v = V2.new
  end

  attr_accessor :v

  def tick dt
    super
    @pos.x += @v.x * dt
    @pos.y += @v.y * dt

  end
end

# TODO stuff hovering the ground and sliding along each other
module Gravity
  def tick dt
    super
    @v.y += dt * 0.01           # axis is downwards # TODO check if this is indepent of screen size
        if @v.y > 0 and @v.y < dt * 0.01
      log "danger"
#      @v.y = 0
#      @pos.y = YWINRES - @size.y
    end
  end
end

# TODO dont have this here
$bounce = 0.8
module Bounded

  @@bounce = $bounce

  def weaken
    @v.x *= @@bounce
    @v.y *= @@bounce
  end

  def tick dt
    super
    # TODO objects "hovering" the bottom freak out sometimes
    if @pos.x < @size.x
      @pos.x = @size.x
      @v.x = -@v.x
      weaken
    end

    if @pos.y < @size.y
      @pos.y = @size.y
      @v.y = -@v.y
      weaken
    end

    if @pos.x > XWINRES - @size.x
      @pos.x = (XWINRES - @size.x) # - (@pos.x - (XWINRES - @size.x))
      @v.x = -@v.x
      weaken
    end

    if @pos.y > YWINRES - @size.y
      @pos.y = (YWINRES - @size.y) #- (@pos.y - (YWINRES - @size.y))
      @v.y = -@v.y
      weaken
    end

  end
end

module DoNotIntersect
  def tick dt
    old_pos = @pos.clone
    super dt

    collider = get_collider(self)

    unless collider.nil?
      @pos = old_pos # TODO having them not move at all is not correct, either
      r1, r2 = collide(self.pos, collider.pos, self.v, collider.v, self.size.x ** 2 , collider.size.x ** 2)

      self.v = r1 * $bounce
      collider.v = r2 * $bounce
    end
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

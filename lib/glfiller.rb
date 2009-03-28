#!/usr/bin/env ruby -wKU

=begin
    # TODO new copyright notice for all filler related stuff...
    tictactoe - tic tac toe game
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

# TODO offer tutorial
# TODO on crash: pause game for some time and mark where crash happened
# TODO profile and speed up code
# TODO have multiple lives
# TODO show "you scored... " on gameover
# FIXME infinite growth in corners possible, generally out of screen growth...
# TODO add sound
# TODO no multiple simultaneous restarts
# TODO seperate backend from graphics so you can stop one at a time...
# TODO seperate graphics from backend -- two files
# TODO reintroduce mode with lots of different images...

# TODO clean these strings
$LOAD_PATH << './lib'

ps = ["/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf",
  "/usr/share/fonts/bitstream-vera/Vera.ttf"
]

if FileTest.exists?(ps[0])
  FONTFILE = ps[0]
elsif FileTest.exists?(ps[1])
  FONTFILE = ps[1]
else
  throw "cannot find font file at neither #{ps[0]} nor #{ps[1]}"
end

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

class Float
  def self.rand min, max
    return min + Kernel.rand(0) * (max - min)
  end
end

class Mouse < Entity
  include Rotating

  attr_accessor :v, :gonna_spawn
  
  def initialize x, y, size
    super x, y, size, size
    @v = Math::V2.new(0, 0)
    @gcolors = @colors = ColorList.new(3) do Color.random(0, 0.8, 0, 0.7) end
    @rcolors = ColorList.new(3) do Color.random(0.8, 0, 0, 0.7) end

    @green = Triangle.new(0, 0, 1, 1)
    @green.colors = @colors
    @pict = Square.new(0, 0, 0.8)

    a = 1.0
    @pict.colors = ColorList.new(4) do Color.new(a, a, a, 1.0) end

    @subs << @green
    @green.subs  << @pict
    
    @rotating = true
    @shrinking = @growing = false
    @gonna_spawn = $tex[rand($tex.length)]


                colors = [ # TODO this is coded two times...
                 # TODO allow disabling this, so that one can use colored images instead of coloring them here...
      # ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end,
      ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end,
      ColorList.new(4) do Color.new(1.0, 1.0, 0.0, 1.0) end,
      ColorList.new(4) do Color.new(0.0, 1.0, 0.0, 1.0) end,
      ColorList.new(4) do Color.new(0.0, 0.0, 1.0, 1.0) end
    ]

#    ball.colors = @spawn_color
     @pict.colors = colors.rand

  end


  def spawn_ball

    # TODO let things have a mass...
    s =  @size.x
    ball = Circle.new(@pos.x, @pos.y, s)

    points = (2 * ball.size.x *  2* ball.size.x * 3.14 / 4) / (XWINRES * YWINRES)

    ball.extend(Velocity)
    ball.reinit2
    ball.extend(Gravity)
    ball.extend(Bounded)
    ball.extend(DoNotIntersect)
    ball.v = self.v.clone.unit
    a= Text.new(0, 0, 5, Color.new(1,0,0,1), FONTFILE, (100 * points).to_i.to_s)
    a.extend(Pulsing); a.reinit
    $engine.timer.call_later(1000) do ball.subs = [] end
    a.r = - ball.r
    ball.subs << a

            colors = [
      # ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end,
      ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end,
      ColorList.new(4) do Color.new(1.0, 1.0, 0.0, 1.0) end,
      ColorList.new(4) do Color.new(0.0, 1.0, 0.0, 1.0) end,
      ColorList.new(4) do Color.new(0.0, 0.0, 1.0, 1.0) end
    ]

    ball.colors = @pict.colors
    @pict.colors = colors.rand




    @growing = false
    @size = V.new($mousedef, $mousedef)


            $engine.objects << ball
      $thing_not_to_intersect << ball

    if (foo = get_collider(ball)).nil?
      $score += points
      $scoreges += points
    else
      game_over
    end

    $m.gonna_spawn = $tex[rand($tex.length)]
    
  
    start_level 1 if $score > 0.5 # TODO use proper level here...
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
    @pict.texture = @gonna_spawn
    
    coll = get_collider(self)
    if coll.nil?
      @green.colors = @gcolors
    else
      @green.colors = @rcolors
    end

  end
end

def collide? obj, obj2 # TODO speedup (the parent method) by sorting them
  dx = obj.pos.x - obj2.pos.x
  dy = obj.pos.y - obj2.pos.y
  #puts "dx #{dx} -- dy #{dy}"
  dx *= dx
  dy *= dy
  dsq = dx + dy
  # for squares/circs
  sizes = (obj.size.x + obj2.size.x) ** 2
  return dsq < sizes
end

def get_collider who # TODO speedup
  res = nil
  $thing_not_to_intersect.each { |thing|
    if thing != who
      res = thing if collide?(who, thing)
    end
  }
  return res
end

def update_gfx dt
  @messages.each { |message| message.tick dt }
  @m.tick dt


  @scoretext.set_text("score: #{($score * 100).to_i}, ges: #{($scoreges * 100).to_i}")
  @scoretext.tick dt

  $engine.objects.each do |x|
    x.tick dt
  end
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



  $engine.objects.each do |x|
    x.render
  end

  @scoretext.render
    @m.render



  $engine.messages.each { |message| message.render }

end

def start_level lvl=0
  if lvl > 0
    go = Text.new(XWINRES/2, YWINRES/2, 320, Color.new(0, 255, 0, 0.8), FONTFILE, "level up!")
    go.extend(Pulsing)
    go.reinit
    $engine.timer.call_later(3000) do $engine.messages = [] end
    $engine.messages << go
  end

  $engine.objects = []

  $thing_not_to_intersect = []# [@m]
  5.times do |t|
    spawn_enemy
  end

  $score = 0
end

def game_over
  # TODO pause the game, and "explain" game over reason
  # $engine.timer.pause
  $scoreges = 0
  go = Text.new(XWINRES/2, YWINRES/2, 320, Color.new(0, 255, 0, 0.8), FONTFILE, "game over!")
  go.extend(Pulsing)
  go.reinit
  #$engine.timer.pause
  $engine.timer.call_later(3000) do $engine.messages = [] end
  $engine.messages << go
  $engine.timer.call_later(3500) do start_level end
end

def spawn_enemy
  begin

    x = Float.rand($mousedef, XWINRES - $mousedef)
    y = Float.rand($mousedef, YWINRES - $mousedef)

    spawning = Circle.new(x, y, $mousedef, $ene[rand($ene.length)])

  end until get_collider(spawning).nil?

  spawning.extend(Velocity)
  spawning.reinit2
  #foo.extend(Gravity)
  spawning.extend(Bounded)
  spawning.extend(DoNotIntersect)
  spawning.v.x = Float.rand(-1,1)
  spawning.v.y = Float.rand(-1,1)
  $engine.objects << spawning
  $thing_not_to_intersect << spawning

  #  end # until get_collider(foo).nil?


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
    game_over
  else
    puts key
  end
end

class Array
  def rand
    return self[Kernel.rand(self.length)]
  end
end

class Circle < Square
  def initialize(x, y, size, text=nil)
    super x, y, size
    @texture = text
    @texture = $m.gonna_spawn if @texture.nil?
    @r = $m.r
    @colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end
end

def on_mouse_down button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
  when SDL::Mouse::BUTTON_LEFT then
    @m.growing = true
  when SDL::Mouse::BUTTON_MIDDLE then
  end
end

def on_mouse_up button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
  when SDL::Mouse::BUTTON_LEFT then
    @m.spawn_ball
  when SDL::Mouse::BUTTON_MIDDLE then
  end
end

def on_mouse_move x, y
  oldx = @m.pos.x
  oldy = @m.pos.y
  @m.pos.x = x
  @m.pos.y = y
  @m.v.x = (@m.pos.x - oldx) #/ 10
  @m.v.y = (@m.pos.y - oldy) #/ 10
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

$mousedef = 40 # TODO cleanup
class GFXEngine
  attr_accessor :messages, :objects, :scoretext

  def prepare
    @messages = []
    @scoretext = Text.new(10, 30, 20, Color.new(255, 100, 255, 1.0), FONTFILE, "SCORE GO HERE")
    @scoretext.extend(TopLeftPositioning)

    $tex = []
    good = "gfx/filler/good/"
    Dir.entries(good).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{good}#{fn}"
      text = Texture.load_file(thef)
      $tex << text
    }

    $ene = []
    bad = "gfx/filler/bad/"
    Dir.entries(bad).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{bad}#{fn}"
      text = Texture.load_file(thef)
      $ene << text
    }

    $m = @m = Mouse.new(100, 100, $mousedef) # TODO unglobalize
    start_level
    $engine.window_title = WINDOWTITLE
  end
end

# TODO move from graphics to backend model!
module Velocity
  def reinit2
    @v = V.new
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

    delta = 3
    suckup = -0.5
    if @pos.y  > YWINRES - @size.y - delta
      @v.y *= 0.3 if @v.y > suckup and @v.y < 0 # TODO need real solution
      return
    end

    @v.y += dt * 0.01 # axis is downwards # TODO check if this is indepent of screen size
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

  def tick dt # TODO cleanup
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
      @pos.x = (XWINRES - @size.x) 
      @v.x = -@v.x
      weaken
    end

    if @pos.y > YWINRES - @size.y
      @pos.y = (YWINRES - @size.y)
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
      @pos = old_pos # TODO having them not move at all is not correct, either -- prevent them from getting stuck to each other
      r1, r2 = Math::collide(self.pos, collider.pos, self.v, collider.v, self.size.x ** 2 , collider.size.x ** 2)

      self.v = r1 * $bounce
      collider.v = r2 * $bounce
    end
  end
end

begin
  puts INFOTEXT
  $engine = GFXEngine.new
  $engine.prepare
  $engine.run!
rescue => exc
  STDERR.puts "there was an error: #{exc.message}"
  STDERR.puts exc.backtrace
end

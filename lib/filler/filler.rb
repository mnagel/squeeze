#!/usr/bin/env ruby -wKU

=begin
    filler - a simple game.
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
# TODO profile and speed up code
# TODO highscore + multiple lives
# TODO game over if spawning out of screen
# TODO add sound effects
# TODO add local/global setting files...

$LOAD_PATH << './lib'

INFOTEXT = <<EOT
    filler - a simple game.
    Copyright (C) 2009 by Michael Nagel

    icons from buuf1.04.3 http://gnome-look.org/content/show.php?content=81153
    icons licensed under Creative Commons BY-NC-SA
EOT

require 'v_math'
# TODO do not depend on gl... some dependencies are messed up here...
require 'glbase'

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

    @pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end


  def spawn_ball
    return unless $engine.engine_running
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
    $engine.external_timer.call_later(1000) do ball.subs = [] end
    a.r = - ball.r
    ball.subs << a

    ball.colors = @pict.colors
    @pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end

    @growing = false
    @size = V.new(Settings.mousedef, Settings.mousedef)

    $engine.objects << ball
    $engine.thing_not_to_intersect << ball

    if (foo = $engine.get_collider(ball)).nil?
      $engine.score += points
      $engine.scoreges += points
    else
      $engine.game_over
    end

    $engine.m.gonna_spawn = $tex[rand($tex.length)]
    
    $engine.start_level($engine.cur_level += 1) if $engine.score > 0.5
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
    grow(+dt * x) if @growing and $engine.engine_running
    grow(-dt * x) if @shrinking and $engine.engine_running
    @pict.texture = @gonna_spawn
    
    coll = $engine.get_collider(self)
    if coll.nil?
      @green.colors = @gcolors
    else
      @green.colors = @rcolors
    end
  end
end

class FillerGameEngine

  attr_accessor :m, :messages, :scoretext, :objects, :thing_not_to_intersect, :score, :scoreges, :cur_level, :ingame_timer, :external_timer, :engine_running

  def update delta
    @external_timer.tick
    return unless @engine_running
    real = delta # TODO to make compiler happy
    real = @ingame_timer.tick

    $engine.objects.each do |x|
      x.tick real
    end
  end

  def prepare
    @ingame_timer = Timer.new
    @external_timer = Timer.new
    @engine_running = true
    @score = @scoreges = 0

    $gfxengine.prepare # TODO put to end, remove things mouse depends on!
    @m = Mouse.new(100, 100, Settings.mousedef)
    @cur_level = 0
    start_level @cur_level
  end

  def collide? obj, obj2 # TODO speedup (the parent method) by sorting them
    dx = obj.pos.x - obj2.pos.x
    dy = obj.pos.y - obj2.pos.y

    dx *= dx
    dy *= dy
    dsq = dx + dy
    # for squares/circs
    sizes = (obj.size.x + obj2.size.x) ** 2
    return dsq < sizes
  end

  def get_collider who # TODO speedup
    res = nil
    @thing_not_to_intersect.each { |thing|
      if thing != who
        res = thing if collide?(who, thing)
      end
    }
    return res
  end

  def start_level lvl
    @engine_running = true
    if lvl > 0
      go = Text.new(XWINRES/2, YWINRES/2, 320, Color.new(0, 255, 0, 0.8), FONTFILE, "level up!")
      go.extend(Pulsing)
      go.reinit
      $engine.external_timer.call_later(3000) do $engine.messages = [] end
      $engine.messages << go
    end

    $engine.objects = []

    @thing_not_to_intersect = []
    (lvl + 2).times do |t|
      spawn_enemy
    end

    @score = 0
  end

  def game_over
    @engine_running = false
    sc = Text.new(XWINRES/2, YWINRES * 0.6, 240, Color.new(255, 255, 255, 0.8), FONTFILE, "#{($engine.scoreges * 100).to_i}")
    go = Text.new(XWINRES/2, YWINRES * 0.4, 320, Color.new(0, 255, 0, 0.8), FONTFILE, "game over!")
    go.extend(Pulsing)
    go.reinit
    sc.extend(Pulsing)
    sc.reinit
    $engine.messages << go << sc
    $engine.ingame_timer.wipe!(false)
    $engine.external_timer.wipe!(false)
    $engine.external_timer.call_later(3000) do $engine.messages = [] end
    $engine.external_timer.call_later(3500) do @scoreges = 0; @cur_level = 0; start_level @cur_level end
  end

  def spawn_enemy
    begin
      x = Float.rand(Settings.mousedef, XWINRES - Settings.mousedef)
      y = Float.rand(Settings.mousedef, YWINRES - Settings.mousedef)

      spawning = Circle.new(x, y, Settings.mousedef, $ene[rand($ene.length)])
    end until get_collider(spawning).nil?

    spawning.extend(Velocity)
    spawning.reinit2
    spawning.extend(Bounded)
    spawning.extend(DoNotIntersect)
    spawning.v.x = Float.rand(-1,1)
    spawning.v.y = Float.rand(-1,1)
    $engine.objects << spawning
    @thing_not_to_intersect << spawning
  end

  def on_key_down key
    case key
    when SDL::Key::ESCAPE then
      $gfxengine.kill!
    when 48 then # Zero
      Settings.show_bounding_boxes = (not Settings.show_bounding_boxes)
    when 97 then # A
      on_mouse_down(SDL::Mouse::BUTTON_MIDDLE, @m.pos.x, @m.pos.y)
    when 98 then # B
      $gfxengine.timer.toggle
    when 103 then # G
      $engine.ingame_timer.toggle
    when 104 then # H
      $gfxengine.timer.toggle
    when SDL::Key::SPACE then
      game_over
    else
      puts key
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
end

class Settings_
  attr_accessor :bounce, :show_bounding_boxes, :mousedef

  def initialize

    @bounce = 0.8
    @show_bounding_boxes = false
    @mousedef = 40
  end
end

Settings = Settings_.new

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $gfxengine.kill!
  elsif event.is_a?(SDL::Event2::KeyDown)
    $engine.on_key_down event.sym
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    $engine.on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseButtonUp)
    $engine.on_mouse_up event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    $engine.on_mouse_move event.x, event.y
  end
end

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

module Bounded
  @@bounce = Settings.bounce

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
  @@bounce = Settings.bounce

  def tick dt
    old_pos = @pos.clone
    super dt

    collider = $engine.get_collider(self)

    unless collider.nil?
      @pos = old_pos # TODO having them not move at all is not correct, either -- prevent them from getting stuck to each other
      r1, r2 = Math::collide(self.pos, collider.pos, self.v, collider.v, self.size.x ** 2 , collider.size.x ** 2)

      self.v = r1 * @@bounce
      collider.v = r2 * @@bounce
    end
  end
end

begin
  require 'glfiller'
  puts INFOTEXT
  $engine = FillerGameEngine.new
  $gfxengine = GFXEngine.new

  $engine.prepare
  $gfxengine.run!
rescue => exc
  STDERR.puts "there was an error: #{exc.message}"
  STDERR.puts exc.backtrace
end
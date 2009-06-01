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

# TODO do proper refactoring of this codebase...
# TODO allow mouse only controls...
# TODO libsdl-ruby1.8 is in hardy!!!
# TODO check if in correct game mode when processing input...
# TODO save scores in home...

# TODO implement wishlist features listed below
=begin
 offer ingame tutorial -- howto inflate, howto score, howto level
 superlinear growth in score
 profile and speed up code
 add sound effects http://www.urbanhonking.com/ideasfordozens/2009/05/early_8bit_sounds_from__whys_b.html
 add local/global setting files...
 document startup script options
=end

require 'glbase'
require 'args_parser'
require 'yaml'

# class to keep track of the current mode the game is in
class GameMode # TODO check against this state all over the place!
  # game is running normal
  NORMAL      = 1
  # player placed a crashing bubble recently
  CRASHED     = 2
  # player is entering name for highscores
  ENTER_NAME  = 3
  # highscore table is displayed
  SHOW_SCORES = 4

  class << self
    # headline when entering a name for highscore
    attr_accessor :enter_name_headline
    # buffer when entering a name for highscore table
    attr_accessor :enter_name_input
    # array of texts for highscores
    attr_accessor :show_highscores_texts
  end
end

# a simple record of a highscore
class HighScore
  attr_accessor :name, :score

  def initialize name, score
    @name, @score = name, score
  end
end

# list of highscore records building the highscore list
class HighScores
  # individual highscore entries
  attr_accessor :entries

  # create new list
  def initialize
    @entries = []
  end

  # get top n entries in order
  def get n
    @entries.sort! { |a,b| a.score <=> b.score }.reverse!
    return @entries.slice(0..n-1)
  end


  # get a file as single string
  # TODO put this somewhere better
  # TODO can fail badly
  def self.get_file_as_string(filename)
    data = ''
    f = File.open(filename, "r")
    f.each_line do |line|
      data += line
    end
    return data
  end

  # enter an entry to the table
  def add name, score
    @entries << HighScore.new(name, score)
  end

  # load table from file
  # TODO make path a param
  def self.load
    return YAML::load(get_file_as_string("my.yaml"))
  end

  # keep only the top n entries
  def truncate n
    limit = get(n).last.score
    @entries.reject! { |item| item.score < limit }
  end

  # save table to file
  # TODO make path a param
  def save
    truncate 5
    serialized = self.to_yaml

    file = File.new("my.yaml", "w")
    file.write(serialized)
    file.close
  end
end

# TODO dispose of global var
$hs =  HighScores.load

class Settings__ < SettingsBase
  attr_accessor :bounce, :show_bounding_boxes, :mousedef, :infotext, :gfx_good, :gfx_bad, :fontsize

  def initialize
    super

    @show_fps = false
    @winX = 1680 #500 # TODO constants for these defaults
    @winY = 1050 #500
    @fullscreen = 1

    # TODO clean up the new settings code...
    switches = []
    @helpswitch = Switch.new('h', 'print help message',	false,
      proc { puts "this is oneshot"; switches.each { |e| puts '-' + e.char + "\t" + e.comm }; Process.exit })
    switches = [
      Switch.new('g', 'select path with gfx (relative to gfx folder)', true, proc {|val| $GFX_PATH = val}),
      Switch.new('f', 'enable fullscreen mode (1/0)', true, proc {|val| @fullscreen = val.to_i}),
      Switch.new('x', 'set x resolution', true, proc {|val| @winX = val.to_i}),
      Switch.new('y', 'set y resolution', true, proc {|val| @winY = val.to_i}),
      @helpswitch
    ]

    fileswitch = proc { |val| puts "dont eat filenames, not even #{val}"};
    #LOG_ERROR = 3
    #noswitch = proc {|someswitch| log "there is no switch '#{someswitch}'\n\n", LOG_ERROR; @helpswitch.code.call; Process.exit };
    #require "logger" # TODO dont use puts below!
    noswitch = proc {|someswitch| puts("there is no switch '#{someswitch}'\n\n", 0, nil); @helpswitch.code.call; Process.exit };

    helpswitch = @helpswitch

    $GFX_PATH = ''
    parse_args(switches, helpswitch, noswitch, fileswitch)

    inf = $GFX_PATH
    inf = '' if inf.nil?

    @fontsize = 150 * @winX / 750.0  # TODO check scaling

    @gfx_good = "gfx/squeeze/#{inf}/good/"
    @gfx_bad = "gfx/squeeze/#{inf}/bad/"
    @win_title = "squeeze by Michael Nagel"
    @bounce = 0.8
    @show_bounding_boxes = false
    @mousedef = 40 * @winX / 750.0 # 40 # TODO introduce vars for 750 and 40
    @infotext  = <<EOT
    squeeze - a simple game.
    Copyright (C) 2009 by Michael Nagel

    icons from buuf1.04.3 http://gnome-look.org/content/show.php?content=81153
    icons licensed under Creative Commons BY-NC-SA
EOT
  end
end

Settings = Settings__.new

class Mouse < Entity
  include Rotating

  attr_accessor :v, :gonna_spawn
  
  def initialize x, y, size
    super x, y, size, size
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

  def can_spawn_here ball
    if   ball.pos.x < ball.size.x           \
        or ball.pos.y < ball.size.y           \
        or ball.pos.x > Settings.winX - ball.size.x \
        or ball.pos.y > Settings.winY - ball.size.y

      return false
    end

    return $engine.get_collider(ball).nil?

  end

  def spawn_ball
    return unless $engine.engine_running
    # TODO let things have a mass...
    s =  @size.x
    ball = Circle.new(@pos.x, @pos.y, s)

    points = $engine.size_to_score ball.size.x

    ball.extend(Velocity)
    ball.extend(Gravity)
    ball.extend(Bounded)
    ball.extend(DoNotIntersect)
    ball.v = self.v.clone.unit
    a = Text.new(0, 0, 5, Color.new(1,0,0,1), Settings.fontfile, (points).to_i.to_s)
    a.extend(Pulsing);
    $engine.external_timer.call_later(1000) do ball.subs = [] end
    a.r = - ball.r
    ball.subs << a

    ball.colors = @pict.colors
    @pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end

    @growing = false
    @size = V.new(Settings.mousedef, Settings.mousedef)

    if can_spawn_here ball
      $engine.score += points
      $engine.scoreges += points
      $engine.objects << ball
      $engine.thing_not_to_intersect << ball

      $engine.m.gonna_spawn = $tex[rand($tex.length)]
      if $engine.score >= $engine.level_up_score # 0.5 # TODO wait a second...
        # $engine.external_timer.call_later(1000) do
        $engine.bonus_score
        $engine.start_level($engine.cur_level += 1)
        # end
      end

    else

      $engine.messages << ball
      $engine.game_over
      ball.subs.clear
    end


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
    return if @size.y < 30 and dsize < 0 # TODO re-ccheck
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
    
    coll = can_spawn_here(self)
    if coll #.nil?
      @green.colors = @gcolors
    else
      @green.colors = @rcolors
    end
  end
end

class SqueezeGameEngine

  attr_accessor :m, :messages, :scoretext, :objects, :thing_not_to_intersect
  attr_accessor :score, :scoreges, :cur_level, :ingame_timer, :external_timer, :engine_running
  attr_accessor :level_up_score, :gamemode

  def size_to_score radius
    area = Math::PI * radius ** 2
    puts area
    perc = area / (Settings.winX * Settings.winY)
    puts perc
    resu = (1 + perc) ** 2 - 1
    puts resu
    retu = [1, (100 * resu).floor].max
    puts retu
    retu
  end

  def punish_score
    @level_up_score += ((@level_up_score - @score) ** 0.35) * 5
    @level_up_score = @level_up_score.floor
  end

  def bonus_score
    bonus = (@score - @level_up_score) ** 1.35
    @scoreges += bonus
  end

  def update delta
    @external_timer.tick
    return unless @engine_running
    real = delta # make netbeans happy
    real = @ingame_timer.tick

    $engine.objects.each do |x|
      x.tick real
    end
  end

  def prepare
    GameMode.enter_name_input = Text.new(Settings.winX/2, Settings.winY/2, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "")
    GameMode.enter_name_headline = Text.new(Settings.winX/2, Settings.winY*0.35, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "enter name")
    @ingame_timer = Timer.new
    @external_timer = Timer.new
    @engine_running = true
    @score = @scoreges = 0

    $gfxengine.prepare # TODO put to end, remove things mouse depends on!
    @m = Mouse.new(100, 100, Settings.mousedef)
    @cur_level = 0
    start_level @cur_level

    @textbuffer = ""

    @gamemode = GameMode::NORMAL

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
    @m.growing = false
    @level_up_score = 100 # 0.5 # TODO proper value
    if lvl > 0
      go = Text.new(Settings.winX/2, Settings.winY/2, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "level up!")
      go.extend(Pulsing)
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
    punish_score
    # TODO block placing new bubbles
    $engine.ingame_timer.pause
    $engine.external_timer.call_later(3000) do $engine.ingame_timer.resume end


    gameoversize = Settings.fontsize
    go = Text.new(Settings.winX/2, Settings.winY * 0.4, gameoversize,
      Color.new(255, 255, 255, 0.8), Settings.fontfile, "crash...")
    sc = Text.new(Settings.winX/2, Settings.winY * 0.6, gameoversize,
      Color.new(255, 255, 255, 0.8), Settings.fontfile, "enter => reset")
    go.extend(Pulsing)
    sc.extend(Pulsing)
    $engine.messages << go << sc # TODO show "press some key to submit score"
    $engine.external_timer.call_later(3000) do $engine.messages = [] end
  end

  def spawn_enemy
    begin
      x = Float.rand(Settings.mousedef, Settings.winX - Settings.mousedef)
      y = Float.rand(Settings.mousedef, Settings.winY - Settings.mousedef)

      spawning = Circle.new(x, y, Settings.mousedef, $ene[rand($ene.length)])
    end until get_collider(spawning).nil?

    spawning.extend(Velocity)
    spawning.extend(Bounded)
    spawning.extend(DoNotIntersect)
    spawning.v.x = Float.rand(-1,1)
    spawning.v.y = Float.rand(-1,1)
    $engine.objects << spawning
    @thing_not_to_intersect << spawning
  end


  def on_key_down key

    # ANY STATE
    case key
    when SDL::Key::ESCAPE then
      $gfxengine.kill!
    when 48 then # Zero
      Settings.show_bounding_boxes = (not Settings.show_bounding_boxes)
      Settings.show_fps = (not Settings.show_fps)
    when 97 then # A
      on_mouse_down(SDL::Mouse::BUTTON_MIDDLE, @m.pos.x, @m.pos.y)
    when 98 then # B
      $gfxengine.timer.toggle
    when 103 then # G
      $engine.ingame_timer.toggle
    when 104 then # H
      $gfxengine.timer.toggle
    when 116 then
      #@textmode = (not @textmode)
    end

    if $engine.gamemode == GameMode::NORMAL
      case key

      when SDL::Key::RETURN then
        # game_over # reset game!
        $engine.ingame_timer.pause
        #@textmode = true
        @textbuffer = ""
        $engine.gamemode = GameMode::ENTER_NAME
        return # TODO fixme, check if needed at other places, too... ... better no multiple ifs...
      else
        puts key
      end

    end

    if $engine.gamemode == GameMode::CRASHED
      case key
      when nil # make compiler happy...
        return

      end

    end

    if $engine.gamemode == GameMode::ENTER_NAME
      case key
      when SDL::Key::RETURN then
        begin

          puts "writing highscore"
          puts "#{@scoreges} -- #{@textbuffer}" # TODO write to class and yaml file
          $hs.add(@textbuffer, @scoreges)
          $hs.save

          #$engine.messages << a = Text.new(0, 0, 5, Color.new(1,0,0,1), Settings.fontfile, "highscores!!!")
          $engine.gamemode = GameMode::SHOW_SCORES
          hs = $hs.get(3) # .first # only one right now # TODO show more
          if hs.nil?
            puts "panic... got a nil"
          end
          GameMode.show_highscores_texts = []
          3.times do |i| GameMode.show_highscores_texts << Text.new(Settings.winX/2, Settings.winY * ((i+2)/5.0),
              Settings.fontsize  * (1/3.0), Color.new(0, 255, 0, 0.8), Settings.fontfile, "#{i+1}. #{hs[i].score} -- #{hs[i].name}")
          end
          puts "GameMode.hs_text was set"

          # TODO now allow resetting game!
          return
        rescue => exc
          puts "foobar"
          exc.show
          return
        end
      else

          puts "not enter"

        @textbuffer += key.chr
        GameMode.enter_name_input.set_text(GameMode.enter_name_input.text + key.chr)
      end
    end


  if $engine.gamemode == GameMode::SHOW_SCORES
    case key
    when SDL::Key::RETURN then
      $engine.messages.clear

      $engine.ingame_timer.resume
      @scoreges = 0; @cur_level = 0; start_level @cur_level
      $engine.gamemode = GameMode::NORMAL

    end

  end
 end

def on_mouse_down button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
    #      beta_method
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
def self.extend_object(o)
  super
  o.instance_eval do @v = V.new end # sneak in the v AUTOMATICALLY...
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
  if @pos.y  > Settings.winY - @size.y - delta
    @v.y *= 0.3 if @v.y > suckup and @v.y < 0 # TODO have another way of letting things rest...
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

def tick dt # TODO rewrite the "bounded" code
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

  if @pos.x > Settings.winX - @size.x
    @pos.x = (Settings.winX - @size.x)
    @v.x = -@v.x
    weaken
  end

  if @pos.y > Settings.winY - @size.y
    @pos.y = (Settings.winY - @size.y)
    @v.y = -@v.y
    weaken
  end
end
end

# module DoNotIntersect
# TODO read about colission detection and resolution
# http://box2d.org/manual.html
# http://dotnetjunkies.com/WebLog/chris.taylor/archive/2006/09/30/148798.aspx
# http://www.cs.unc.edu/~geom/collide/
# http://www.ziggyware.com/readarticle.php?article_id=52
# http://www.realtimerendering.com/
# http://forums.xna.com/forums/t/17303.aspx
# http://www.eetsgame.com/PPCD/#_Toc44013734
# http://www.cs.unc.edu/~geom/index.shtml
# http://games.fourtwo.se/xna/2d_collision_response_xna/
# http://en.wikipedia.org/wiki/Collision_detection
# http://web.comlab.ox.ac.uk/people/Stephen.Cameron/distances/
# http://chrishecker.com/Rigid_Body_Dynamics

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
require 'glsqueeze' # TODO do not have constant here
puts Settings.infotext
$engine = SqueezeGameEngine.new
$gfxengine = GLFrameWork.new

$engine.prepare
$gfxengine.run!
rescue => exc
STDERR.puts "there was an error: #{exc.message}"
STDERR.puts exc.backtrace
end

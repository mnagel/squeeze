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

# TODO beim zweiten Durchlauf manchmal kein Pumpen
# in den höheren Levels, wo es ja sehr eng wird, scheint mir kein 100%iger
# Verlass auf die roten und grünen Ecken um den Spielball herum zu sein.
# Ich habe öfter erlebt, dass es einen Crash gab, obwohl ich mir sicher war,
# die Ecken waren noch grün. Und dann ist mit den Strafpunkten ja alles verloren.

# TODO block multiple messages at one time
# TODO WISHLIST offer ingame tutorial -- howto inflate, howto score, howto level
# TODO WISHLIST profile and speed up code
# TODO WISHLIST add local/global setting files...
# TODO WISHLIST document startup script options
# TODO WISHLIST document superlinear and special scoring...
# TODO add background picture
# TODO more sounds -- level up, game over, highscore, ...
# FIXME submitting scores bug... shown twice sometimes...

require 'glbase'
require 'args_parser'
require 'yaml'
require 'physics'

require 'time'
require 'date'
DATEFORMAT = "%Y-%m-%d %H:%M:%S"

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

  NONE        = 0

  class << self
    # headline when entering a name for highscore
    attr_accessor :enter_name_headline
    # buffer when entering a name for highscore table
    attr_accessor :enter_name_input
    # array of texts for highscores
    attr_accessor :show_highscores_texts
    # fader
    attr_accessor :fader
  end

  def self.set_mode mode
    $engine.gamemode = mode
  end

  def self.get_mode
    $engine.gamemode
  end
end

# TODO sanatize to ints only, make level-up callback, add level management here...
class Score
  attr_accessor :score, :scoreges, :cur_level, :level_up_score

  def initialize
    @scoreges, @score = 0, 0
  end

  def level_up
    @score = 0
  end

  def score_points points
    @score += points
    @scoreges += points
  end

  def to_highscore name
    res = HighScore.new(name, @scoreges)
    res.date = Time.now.strftime(DATEFORMAT)
    res.comment = "comment: score = #{@score}; level = #{@cur_level}"
    return res
  end
end

# a simple record of a highscore
class HighScore
  attr_accessor :name, :score, :date, :comment

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
    puts "init of highscores..."
  end

  # get top n entries in order
  def get n
    @entries.sort! { |a,b| a.score <=> b.score }.reverse! # order by date as second criterium
    return @entries.slice(0..n-1)
  end

  def is_in_best val, n
    ref = (get n).last.score
    return val > ref
  end

  # enter an entry to the table
  def add name, score_object
    @entries << score_object.to_highscore(name)
  end

  # load table from file
  def self.load path
    if File.exist? path
      puts "reading highscore from #{path}"
      return YAML::load(get_file_as_string(path))
    else
      puts "creating new highscore"
      a = HighScores.new
      puts "hs in method is #{a.to_s}"
      a.add "nobody", 100
      a.add "nobody", 500
      a.add "nobody", 1000
      puts "hs in method is #{a.to_s}"
      return a
    end
  end

  # keep only the top n entries
  def truncate n
    limit = get(n).last.score
    @entries.reject! { |item| item.score < limit }
  end

  # save table to file
  def save path
    truncate 5
    serialized = self.to_yaml

    file = File.new(path, "w")
    file.write(serialized)
    file.close
  end
end

# TODO put this somewhere else and delay till startup...
# TODO dispose of global var
HIGHSCOREFILEPATH = "#{ENV['HOME']}/.squeeze.hs.yaml"
$hs =  HighScores.load HIGHSCOREFILEPATH
#puts "hs is #{$hs.to_s}"

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

  attr_accessor :v, :gonna_spawn, :pict
  
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
    
    coll = $engine.can_spawn_here(self)
    if coll #.nil?
      @green.colors = @gcolors
    else
      @green.colors = @rcolors
    end
  end
end

class SqueezeGameEngine

    def can_spawn_here ball
    if   ball.pos.x < ball.size.x           \
        or ball.pos.y < ball.size.y           \
        or ball.pos.x > Settings.winX - ball.size.x \
        or ball.pos.y > Settings.winY - ball.size.y

      return false
    end

    return $engine.get_collider(ball).nil?

  end

  def spawn_ball mouse
    return unless $engine.engine_running
    # TODO let things have a mass...
    s =  mouse.size.x
    ball = Circle.new(mouse.pos.x, mouse.pos.y, s)

    points = $engine.size_to_score ball.size.x

    ball.extend(Velocity)
    ball.extend(Gravity)
    ball.extend(Bounded)
    ball.extend(DoNotIntersect)
    ball.v = mouse.v.clone.unit
    a = Text.new(0, 0, 5, Color.new(1,0,0,1), Settings.fontfile, (points).to_i.to_s)
    a.extend(Pulsing);
    $engine.external_timer.call_later(1000) do ball.subs = [] end
    a.r = - ball.r
    ball.subs << a

    ball.colors = mouse.pict.colors
    mouse.pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end

    mouse.growing = false
    mouse.size = V.new(Settings.mousedef, Settings.mousedef)

    if can_spawn_here ball
      SDL::Mixer.play_channel(1, $sound, 0)
      # TODO put sound code elsewhere.
      # investigate http://www.urbanhonking.com/ideasfordozens/2009/05/early_8bit_sounds_from__whys_b.html
      $engine.score_object.score_points points
      $engine.objects << ball
      $engine.thing_not_to_intersect << ball

      $engine.m.gonna_spawn = $tex[rand($tex.length)]
#      # TODO wait a second...
       if $engine.score_object.score >= $engine.score_object.level_up_score
        # $engine.external_timer.call_later(1000) do
        $engine.bonus_score
        $engine.start_level($engine.score_object.cur_level += 1)
        # end
      end

    else

      $engine.messages << ball
      $engine.game_over
      ball.subs.clear
    end


  end

  attr_accessor :m, :messages, :scoretext, :objects, :thing_not_to_intersect
  attr_accessor :score_object, :ingame_timer, :external_timer, :engine_running
  attr_accessor :gamemode

  def size_to_score radius
    area = Math::PI * radius ** 2
    #    puts area
    perc = area / (Settings.winX * Settings.winY)
    #    puts perc
    resu = (1 + perc) ** 2 - 1
    #    puts resu
    retu = [1, (100 * resu).floor].max
    #    puts retu
    retu
  end

  def punish_score
    @score_object.level_up_score += ((@score_object.level_up_score - @score_object.score) ** 0.35) * 5
    @score_object.level_up_score = @score_object.level_up_score.floor
  end

  def bonus_score
    bonus = (@score_object.score - @score_object.level_up_score) ** 1.35
    @score_object.scoreges += bonus
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

  # run after real initialization, when all needed resources are available
  def initialize!
    magic_buffer_size = 512
    SDL::Mixer.open(frequency=SDL::Mixer::DEFAULT_FREQUENCY,format=SDL::Mixer::DEFAULT_FORMAT,cannels=SDL::Mixer::DEFAULT_CHANNELS,magic_buffer_size)
    $sound = SDL::Mixer::Wave.load("sfx/create.wav")

    GameMode.enter_name_input = Text.new(Settings.winX/2, Settings.winY/2, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "")
    GameMode.enter_name_headline = Text.new(Settings.winX/2, Settings.winY*0.35, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "enter name")

    GameMode.fader = Rect.new(0, 0, Settings.winX, Settings.winY)
    GameMode.fader.colors = ColorList.new(4) { |i| Color.new(0, 0, 0, 0.8) }

    @ingame_timer = Timer.new
    @external_timer = Timer.new
    @engine_running = true
    @score_object = Score.new

    $gfxengine.prepare # TODO put to end, remove things mouse depends on!
    @m = Mouse.new(100, 100, Settings.mousedef)
    @score_object.cur_level = 0
    start_level @score_object.cur_level
    @textbuffer = ""
    GameMode.set_mode(GameMode::NORMAL)
  end

  def prepare
    initialize!
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
    @score_object.level_up_score = 100 # 0.5 # TODO proper value
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

    @score_object.level_up
  end

  def game_over
    punish_score
    GameMode.set_mode(GameMode::CRASHED)
    $engine.ingame_timer.pause
    $engine.external_timer.call_later(3000) do $engine.ingame_timer.resume end


    gameoversize = Settings.fontsize
    go = Text.new(Settings.winX/2, Settings.winY * 0.4, gameoversize,
      Color.new(255, 255, 255, 0.8), Settings.fontfile, "crash...")
    sc = Text.new(Settings.winX/2, Settings.winY * 0.6, gameoversize,
      Color.new(255, 255, 255, 0.8), Settings.fontfile, "enter => reset")
    go.extend(Pulsing)
    sc.extend(Pulsing)
    $engine.messages << go << sc
    $engine.external_timer.call_later(3000) do $engine.messages = []; GameMode.set_mode(GameMode::NORMAL) end
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

  def create_highscore_texts
    hs = $hs.get(3)
    puts "panic... got a nil" if hs.nil?
    GameMode.show_highscores_texts = []

    3.times do |i| GameMode.show_highscores_texts << Text.new(Settings.winX/2, Settings.winY * ((i+2)/5.0),
        Settings.fontsize  * (1/3.0), Color.new(0, 255, 0, 0.8), Settings.fontfile, "#{i+1}. #{hs[i].score.to_i} -- #{hs[i].name}")
    end
  end

  def user_ends_game
        $engine.ingame_timer.pause
        @textbuffer = ""
        GameMode.enter_name_input.set_text(@textbuffer)
        if $hs.is_in_best($engine.score_object.scoreges, 3)
          GameMode.set_mode(GameMode::ENTER_NAME)
        else
          GameMode.set_mode(GameMode::SHOW_SCORES)
          create_highscore_texts
        end
  end

  def on_key_down key, event
    # ANY STATE
    # TODO require right shift to be pressed to stop accidential invoking
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

    case GameMode.get_mode
    when GameMode::NORMAL
      case key
      when SDL::Key::RETURN then
        user_ends_game
      else
        puts SDL::Key.getKeyName(key)
      end

    when GameMode::CRASHED
      case key
      when SDL::Key::RETURN then
        user_ends_game
      when nil then return # make compiler happy...
      end

    when GameMode::ENTER_NAME
      case key
      when SDL::Key::RETURN then
        begin
          $hs.add(@textbuffer, @score_object) # TODO no global variable
          $hs.save HIGHSCOREFILEPATH

          GameMode.set_mode(GameMode::SHOW_SCORES)
          hs = $hs.get(3) 
          puts "panic... got a nil" if hs.nil?
          GameMode.show_highscores_texts = []

          3.times do |i| GameMode.show_highscores_texts << Text.new(Settings.winX/2, Settings.winY * ((i+2)/5.0),
              Settings.fontsize  * (1/3.0), Color.new(0, 255, 0, 0.8), Settings.fontfile, "#{i+1}. #{hs[i].score} -- #{hs[i].name}")
          end

          return
        rescue => exc
          exc.show
          return
        end
      else
        begin
          input = key.chr
          if key == SDL::Key::BACKSPACE
            @textbuffer.chop! # FIXME does not work really

            GameMode.enter_name_input.set_text(@textbuffer)
            return
          end
          is_ok = /[a-zA-z0-9 ]/.match(input)

          bla = event.mod
          bla &= SDL::Key::MOD_SHIFT
          input.upcase! unless bla == 0

          return unless is_ok

          @textbuffer += input
          GameMode.enter_name_input.set_text(@textbuffer)
        rescue => exc
          exc.show
        end
      end

    when GameMode::SHOW_SCORES
      case key
      when SDL::Key::RETURN then
        $engine.messages.clear

        $engine.ingame_timer.resume
        @score_object = Score.new
        @score_object.cur_level = 0
        start_level @score_object.cur_level
        GameMode.set_mode(GameMode::NORMAL)
      end
    end
  end

  def on_mouse_down button, x, y
    case GameMode.get_mode
    when GameMode::NORMAL
      case button
      when SDL::Mouse::BUTTON_RIGHT then
      when SDL::Mouse::BUTTON_LEFT then
        @m.growing = true
      when SDL::Mouse::BUTTON_MIDDLE then
      end
    end
  end

  def on_mouse_up button, x, y
    case GameMode.get_mode
    when GameMode::NORMAL
      case button
      when SDL::Mouse::BUTTON_RIGHT then
      when SDL::Mouse::BUTTON_LEFT then
        $engine.spawn_ball(@m)
      when SDL::Mouse::BUTTON_MIDDLE then
      end
    when GameMode::CRASHED then
      $engine.external_timer.wipe! true if button == SDL::Mouse::BUTTON_LEFT
    end
  end

  def on_mouse_move x, y
    case GameMode.get_mode
    when GameMode::NONE
    else
      oldx = @m.pos.x
      oldy = @m.pos.y
      @m.pos.x = x
      @m.pos.y = y
      @m.v.x = (@m.pos.x - oldx)
      @m.v.y = (@m.pos.y - oldy)
    end
  end
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $gfxengine.kill!
  elsif event.is_a?(SDL::Event2::KeyDown)
    $engine.on_key_down event.sym, event
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    $engine.on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseButtonUp)
    $engine.on_mouse_up event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    $engine.on_mouse_move event.x, event.y
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

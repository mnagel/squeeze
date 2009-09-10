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

# TODO block multiple messages at one time
# TODO WISHLIST offer ingame tutorial -- howto inflate, howto score, howto level
# TODO WISHLIST profile and speed up code
# TODO WISHLIST add local/global setting files...
# TODO WISHLIST document startup script options
# TODO WISHLIST document superlinear and special scoring...
# FIXME submitting scores bug... shown twice sometimes...
# TODO version number in game
# TODO add .desktop file
# TODO michel: unterschiedliche punkte für unterschiedliche farben
# TODO quadtree for faster collission detection
# TODO sounds gleichlaut
# TODO kugelrotation wird beim erstellen einer kugel nicht uebernommen
# TODO skript to install all packages squeeze depends on

# TODO nochmal zu squeeze: ich würde mich freuen, wenn ich immer zwischendurch sehen
#könnte, wieviele Punkte ich pro Level erzielt habe, ev. würde auch die Angabe
#des Levels reichen. Ich habe festgestellt, dass ich hohe Punktzahlen nur
#erreiche, wenn ich möglichst früh sehr viele Punkte mache.
#Und da erscheine ich niiiiiie bei Highscore und hätte deshalb meinen
#eigenen Spaß, wenn ich wenigstens sehen könnte, wie weit ich in der
#Relation Punkte/ Level bin. Kapiert? Dann kannst du das ja mal ändern?!

# TODO document, that pngs need be rgbA
# TODO correctly rotate spawned bubble
# TODO document switches (sound...)
# TODO switch for differnt highscore file
# TODO check if .svn excluded from releases (ls -lahR)

require 'glbase'
require 'args_parser'
require 'yaml'

require 'time'
require 'date'
DATEFORMAT = "%Y-%m-%d %H:%M:%S"

require 'physics'
require 'highscore'
require 'settings'
require 'sound'
require 'mouse'

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

  def spawn_ball mouse # TODO copy rotation from original (and add switch to override (photo mode))
    return unless $engine.engine_running
    # TODO let things have a mass...
    ball = Circle.new(mouse.model.pos.x, mouse.model.pos.y, mouse.model.size.x)

    points = $engine.size_to_score ball.size.x

    ball.extend(Velocity)
    ball.extend(Gravity)
    ball.extend(Bounded)
    ball.extend(DoNotIntersect)
    ball.v = mouse.model.v.clone.unit
    a = Text.new(0, 0, 5, Color.new(1,0,0,1), Settings.fontfile, (points).to_i.to_s)
    a.extend(Pulsing);
    $engine.external_timer.call_later(1000) do ball.subs = [] end
    a.r = - ball.r
    ball.subs << a

    ball.colors = mouse.view.pict.colors
    mouse.view.pict.colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end

    mouse.model.growing = false
          mouse.model.reset_after_spawn
    mouse.model.size = V.new(Settings.mousedef, Settings.mousedef)

    if can_spawn_here ball
      $sfxengine.play :create
      # TODO put sound code elsewhere.
      $engine.score_object.score_points points
      $engine.objects << ball
      $engine.thing_not_to_intersect << ball

      $engine.mouse.view.gonna_spawn = $tex[rand($tex.length)]
#      # TODO wait a second...
       if $engine.score_object.score >= $engine.score_object.level_up_score
        # $engine.external_timer.call_later(1000) do
        $engine.bonus_score
        $engine.start_level($engine.score_object.cur_level += 1)
        # end
      end

    else
      $sfxengine.play :crash
      $engine.messages << ball
      $engine.game_over
      ball.subs.clear
    end
  end

  attr_accessor :mouse, :messages, :scoretext, :objects, :thing_not_to_intersect
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
    $sfxengine = SoundEngine.new

    GameMode.enter_name_input = Text.new(Settings.winX/2, Settings.winY/2, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "")
    GameMode.enter_name_headline = Text.new(Settings.winX/2, Settings.winY*0.35, Settings.fontsize, Color.new(0, 255, 0, 0.8), Settings.fontfile, "enter name")

    GameMode.fader = Rect.new(0, 0, Settings.winX, Settings.winY)
    GameMode.fader.colors = ColorList.new(4) { |i| Color.new(0, 0, 0, 0.8) }

    @ingame_timer = Timer.new
    @external_timer = Timer.new
    @engine_running = true
    @score_object = Score.new

    $gfxengine.prepare # TODO put to end, remove things mouse depends on!
    @mouse = Mouse.new(100, 100, Settings.mousedef)
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
    @mouse.model.growing = false
    @score_object.level_up_score = 100 # 0.5 # TODO proper value
    if lvl > 0
      $sfxengine.play :levelup
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

  def user_ends_game
        $engine.ingame_timer.pause
        @textbuffer = ""
        GameMode.enter_name_input.set_text(@textbuffer)
        if $hs.is_in_best($engine.score_object.scoreges, 3)
          GameMode.set_mode(GameMode::ENTER_NAME)
          $sfxengine.play :highscore
        else
          GameMode.set_mode(GameMode::SHOW_SCORES)
          $sfxengine.play :gameover
          create_highscore_texts
        end
  end

  def on_key_down key, event
    case key
    when SDL::Key::ESCAPE then
      $gfxengine.kill!
    when 48 then # Zero
      Settings.show_bounding_boxes = (not Settings.show_bounding_boxes)
      Settings.show_fps = (not Settings.show_fps)
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
          create_highscore_texts
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

          modifier = event.mod
          modifier &= SDL::Key::MOD_SHIFT
          input.upcase! unless modifier == 0

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
        @mouse.model.growing = true
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
        $engine.spawn_ball(@mouse)
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
      oldx = @mouse.model.pos.x
      oldy = @mouse.model.pos.y
      @mouse.model.pos.x = x
      @mouse.model.pos.y = y
      @mouse.model.v.x = (@mouse.model.pos.x - oldx)
      @mouse.model.v.y = (@mouse.model.pos.y - oldy)
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

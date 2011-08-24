=begin
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

=end

require 'glbase'
require 'tictactoe'

class Settings__ < SettingsBase
  attr_accessor :show_bounding_boxes, :infotext

  def initialize
    super

    @win_title = "gltictactoe.rb by Michael Nagel"

    @infotext = <<EOT
    tictactoe - tic tac toe game
    Copyright (C) 2008, 2009 by Michael Nagel
EOT

    @show_bounding_boxes = false
  end
end

Settings = Settings__.new

class Mark
  alias_method :original, :initialize
  attr_accessor :gfx

  def initialize x, y
    original(x, y)
    @gfx = MarkGFX.new(100+(x)*200,100+y*200, 80, self,
      :color_p1 => ColorList.new(3) do Color.random(1, 0, 0) end,
      :color_p2 => ColorList.new(3) do Color.random(0, 0, 1) end)
    @gfx.extend(Pulsing)
    @gfx.pulsing = false
  end
end

class TicTacToeGL < TicTacToe
  def on_game_won winner, winning_stones

    puts "game was won by #{winner}, with stones #{winning_stones}"
    super winner, winning_stones
    winning_stones.each { |item|
      item.gfx.pulsing = true
    }

    $gfxengine.message = Text.new(Settings.winX/2, Settings.winY/2, 120,
      Color.new(0, 255, 0, 0.8), Settings.fontfile, "PLAYER #{winner} WINS!")
    $gfxengine.message.extend(Pulsing)
    $welcome.visible = false
    $gfxengine.timer.call_later(3000) do $gfxengine.message = nil end
  end

  def on_gameover
    return unless check_winner.nil?
    $gfxengine.message = Text.new(Settings.winX/2, Settings.winY/2, 320,
      Color.new(0, 255, 0, 0.8), Settings.fontfile, "DRAW")
    $gfxengine.message.extend(Pulsing)
    $welcome.visible = false
    $gfxengine.timer.call_later(3000) do $gfxengine.message = nil end

  end

  def on_game_start
    super
    return if $welcome.nil?
    $gfxengine.timer.wipe!
    $welcome.visible = true
    $gfxengine.timer.call_later(3000) do $welcome.visible = false end
  end
end

class Mouse < Entity
  include Rotating

  def initialize x, y, size, color_hash
    super x, y, size, size
    @colors = color_hash[:colors_out]
    @colors_in = color_hash[:colors_in]

    @textures = [Texture.none, $p1, $p2]

    @green = Triangle.new(0, 0, 1, 1)
    @green.colors = @colors

    @sign = Triangle.new(0, 0, 0.5,0.5)
    @sign.colors = @colors_in[$game.player]

    @pict = Square.new(0, 0, 0.8)
    a = 1.0
    @pict.colors = ColorList.new(4) do Color.new(a, a, a, 1.0) end

    @subs << @green
    @green.subs << @sign
    @sign.subs  << @pict

    @rotating = true
    tick 0
  end

  def tick dt
    super dt
    @sign.colors  = @colors_in[$game.player]
    @pict.texture = @textures[$game.player]
    @pict.visible = (not $game.gameover?)
  end

end

class MarkGFX < Triangle
  include Rotating

  def initialize x, y, size, mark, color_hash
    super x, y, size, size
    @c1 = color_hash[:color_p1]
    @c2 = color_hash[:color_p2]
    @mark = mark
    @visible = false

    @rotating = true

    subs << Square.new(0, 0, 0.5)
    subs.first.colors = ColorList.new(4) do Color.random(255, 255, 255) end
    subs.each do |s| s.visible = false end
  end

  def tick dt
    super

    if @mark.nil? or @mark.player == 0
      @visible = false
      return
    else
      @visible = true
      subs.each do |s| s.visible = true end
    end

    case @mark.player
    when 1 then self.colors = @c1; subs.first.texture = $p1
    else self.colors = @c2; subs.first.texture = $p2
    end
  end
end

# TODO use lines from glbase...
def draw_grid
  GL::LineWidth(2.8)
  a = 0.5
  @c = [0,a,0,1]
  @d = [0,a,0,1]

  GL.Begin(GL::LINES)
  for x in [200,400]
    GL.Color(  @c)
    for y in [50,550]
      GL.Vertex3f( x, y, 0.0)
      GL.Color(  @d)
    end
  end

  for x2 in [200,400]
    GL.Color(  @c)
    for y2 in [50,550]
      GL.Vertex3f( y2, x2, 0.0)
      GL.Color(  @d)
    end
  end

  GL.End()
end

def update_gfx dt
  $game.field.each { |x,y,o|
    o.gfx.tick dt
  }

  @m.tick dt

  unless $gfxengine.message.nil?
    $gfxengine.message.tick dt
  end

  $welcome.tick dt
end

def draw_gl_scene
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  define_screen 600, 600
  draw_grid

  $game.field.each { |x,y,o|
    o.gfx.render
  }

  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)
  @m.render

  unless $gfxengine.message.nil?
    $gfxengine.message.render
  end

  $welcome.render
end

def on_key_down key
  case key
  when SDL::Key::ESCAPE then
    $gfxengine.kill!
  when 48 then # Zero
    unless $game.gameover?
      a, b = $game.ki_get_move;
      $game.do_move(a,b)
    end
  when 97 then # A
    on_key_down(SDL::Key::SPACE)
    10.times { on_key_down(48) }
  when 98 then # B
    $gfxengine.timer.toggle
  when SDL::Key::SPACE then
    $game = TicTacToeGL.new
  else
    puts key
  end
end

def on_mouse_down button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT then
    $game = TicTacToeGL.new
  when SDL::Mouse::BUTTON_LEFT then
    fx = (x / (Settings.winX/3)).to_i # TODO add method to calculate coordinates
    fy = (y / (Settings.winY/3)).to_i
    unless $game.gameover?
      $game.do_move(fx,fy)
    end
  when SDL::Mouse::BUTTON_MIDDLE then
    unless $game.gameover?
      a, b = $game.ki_get_move;
      $game.do_move(a,b)
    end
  end
end

def on_mouse_move x, y
  @m.pos.x = x
  @m.pos.y = y
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $gfxengine.kill!
  elsif event.is_a?(SDL::Event2::KeyDown)
    on_key_down event.sym
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    on_mouse_move event.x, event.y
  end
end

class GLFrameWork
  attr_accessor :message

  def prepare
    $welcome = nil
    $game = TicTacToeGL.new
    $gfxengine.message = nil

    $p1 = Texture.load_file("gfx/a.png")
    $p2 = Texture.load_file("gfx/b.png")
    @m = Mouse.new(100, 100, 100,
      :colors_in => [
        ColorList.new(3) do Color.random(1, 1, 1, 0.1) end, # gameover
        ColorList.new(3) do Color.random(1, 0, 0, 0.7) end, # p1
        ColorList.new(3) do Color.random(0, 0, 1, 0.7) end  # p2
      ],
      :colors_out =>
        ColorList.new(3) do Color.random(0, 0.8, 0, 0.7) end)

    $welcome = Text.new(Settings.winX/2, Settings.winY/2, 120,
      Color.new(255, 0, 0, 0.8), Settings.fontfile, "TIC TAC TOE")
    $gfxengine.timer.call_later(3000) do $welcome.visible = false end
    $welcome.extend(Pulsing)
  end
end

begin
  puts Settings.infotext
  $gfxengine = GLFrameWork.new
  $gfxengine.prepare
  $gfxengine.run!
rescue => exc
  STDERR.puts "there was an error: #{exc.message}"
  STDERR.puts exc.backtrace
end

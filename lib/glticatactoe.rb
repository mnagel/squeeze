#!/usr/bin/env ruby

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

require "sdl"
require "opengl"

require 'tictactoe'
require 'glbase'

TAN30 = 0.577;

class Float
  def self.rand min, max
    return min + Kernel.rand(0) * (max - min)
  end
end

class Mark
  alias_method :original, :initialize 
  attr_accessor :gfx
  
  def initialize x, y
    original(x, y)
    @gfx = MarkGFX.new(100+(x)*200,100+((2-y))*200, 80, self, 
      :color_p1 => Array.new(3) do Color.random(1, 0, 0) end,  :color_p2 => Array.new(3) do Color.random(0, 0, 1) end)
    @gfx.rotating = true
  end
end

class Mouse < OpenGLPrimitive
  def initialize x, y, size, color_hash
    super x, y, size
    @colors_in = color_hash[:colors_in]
    #shape = Square # FIXME!!!
    shape = Triangle
    @subs << shape.new(0, 0, 1, color_hash[:colors_out])
    @subs.last.subs << Triangle.new(0, 0, 0.5, @colors_in[1])
  end
  
  def tick dt
    super dt
    @subs.last.subs.last.colors = @colors_in[$game.player]
  end
end

class MarkGFX < Triangle
  
  def initialize x, y, size, mark, color_hash
    puts color_hash
    super x, y, size, color_hash[:color_p1]
    @c1 = color_hash[:color_p1]
    @c2 = color_hash[:color_p2]
    @mark = mark
    @visible = false
    
    subs << Square.new(0, 0, 0.5, Array.new(4) do Color.random(255, 255, 255) end)
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
    
    self.pulsing = @mark.winner
    
    case @mark.player
    when 1 then self.colors = @c1; subs.first.gltexture = $p1.handle
    else self.colors = @c2; subs.first.gltexture = $p2.handle
    end
  end
end

def draw_grid
  GL::LineWidth(2.8)
  @c = [1,1,0,1]
  @d = [1,0,1,1]                  
  
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

def draw_gl_scene dt
  define_screen 600, 600
  draw_grid
  
  $game.field.each { |x,y,o| 
    o.gfx.render
    o.gfx.tick dt
  }
  
  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)
  @m.tick dt
  @m.render

  $bla.each do |x| x.tick dt; x.render end
  $bla.first.set_text "rendering @#{$engine.timer.ticks_per_second}fps"
end

$x = false
def on_key_down key
  $x = (not $x)
  #@m.pulsing = (not @m.pulsing)
  case key
  when SDL::Key::ESCAPE :
      $engine.kill!
  when 48 : # Zero
    unless $game.gameover?
      a, b = $game.ki_get_move; 
      $game.do_move(a,b) 
      puts $game.to_s
    end
  when 97 : # A
    on_key_down(SDL::Key::SPACE)
    10.times { on_key_down(48) }
  when 98 : # B
    $engine.timer.toggle
  when SDL::Key::SPACE :
      $game = TicTacToe.new
    puts $game.to_s
  else
    puts key
  end
end

def on_mouse_down button, x, y
  case button
  when SDL::Mouse::BUTTON_RIGHT :
      $game = TicTacToe.new
    puts $game.to_s
  when SDL::Mouse::BUTTON_LEFT :
      fx = (x / (XWINRES/3)).to_i
    fy = (y / (YWINRES/3)).to_i
    unless $game.gameover?
      $game.do_move(fx,fy) 
      puts $game.to_s
    end
  when SDL::Mouse::BUTTON_MIDDLE :
      unless $game.gameover?
      a, b = $game.ki_get_move; 
      $game.do_move(a,b) 
      puts $game.to_s
    end    
  end
end

def on_mouse_move x, y
  @m.x = x
  @m.y = YWINRES-y
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $engine.kill!
  elsif event.is_a?(SDL::Event2::KeyDown)
    on_key_down event.sym
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    on_mouse_move event.x, event.y
  end
end

class Engine
  alias_method :prepare_original, :prepare
def prepare
  prepare_original
  $game = TicTacToe.new
#  puts $game.to_s
  @m = Mouse.new(100, 100, 100, 
    :colors_in => [
      Array.new(3) do Color.random(1, 1, 1, 0.1) end, # gameover
      Array.new(3) do Color.random(1, 0, 0) end, # pq
      Array.new(3) do Color.random(0, 0, 1) end  # p2
    ],  
    :colors_out => 
      Array.new(3) do Color.random(0, 0.8, 0) end)
  @m.rotating = true
  @m.pulsing = true

  $bla = [Text.new(5, 5, 20, Color.new(255, 100, 255, 1.0), "font.ttf", "hallo")]
 
  $welcome = Text.new(100, 400, 120, Color.new(255, 0, 0, 0.8), "font.ttf", "WELCOME")
  $welcome.pulsing = true
  $engine.timer.call_later(3000) do $welcome.visible = false end
  $bla << $welcome
  
  $p1 = Texture.new("gfx/a.png")
  $p2 = Texture.new("gfx/b.png")
end
end

begin
$engine = Engine.new
$engine.prepare
$engine.run!
rescue => exc
  STDERR.puts "there was an error: #{exc.message}"
  STDERR.puts exc.backtrace
end



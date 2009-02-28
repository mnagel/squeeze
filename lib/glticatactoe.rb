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
    @gfx = MarkGFX.new(100+(x)*200,100+((2-y))*200, 80, nil)
    @gfx.mark = self
    @gfx.rotating = true
  end
end

class MarkGFX < Triangle
  attr_accessor :mark
  
  # TODO improve this
  def render
    super unless @colors.nil?
  end
  
  # TODO improve this!
  def tick dt
    super
    return if @mark.nil? or @mark.player == 0
    self.pulsing = true if @mark.winner
    
    if @colors.nil?
      if @mark.player == 1
        @colors = Array.new(3) do Color.random(1, 0, 0) end
      elsif @mark.player == 2
        @colors = Array.new(3) do Color.random(0, 0, 1) end
      end
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
  
  for x in [200,400]
    GL.Color(  @c)  
    for y in [50,550]
      GL.Vertex3f( y, x, 0.0) 
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
  
  $image.tick dt
  #$image.render #100, 100, 0
  drawtext $font, 1, 0, 255, 10, 10, 0, "rendering @#{$fps}fps"
end

def on_key_down key
  @m.pulsing = (not @m.pulsing)
  case key
  when SDL::Key::ESCAPE :
      $running = false
  when 48 : # Zero
    unless $game.gameover?
      a, b = $game.ki_get_move; 
      $game.do_move(a,b) 
      puts $game.to_s
    end
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
  
  $image.x = x
  $image.y = YWINRES - y
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $running = false
  elsif event.is_a?(SDL::Event2::KeyDown)
    on_key_down event.sym
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    on_mouse_down event.button, event.x, event.y
  elsif event.is_a?(SDL::Event2::MouseMotion)
    on_mouse_move event.x, event.y
  end
end

def startup
  $game = TicTacToe.new
  puts $game.to_s
  @m = Triangle.new(100, 100, 100, Color.new(0,1,0,0.7)) #Mouse.new(200,200)
  @m.rotating = true
  @m.pulsing = true
  $image = ImageTexture.new("gfx/pic.png", 512)
end

run!

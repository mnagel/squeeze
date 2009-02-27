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

class Color
  attr_accessor :r, :g, :b, :a
  
  def initialize r, g, b, a=1
    @r, @g, @b, @a = r, g, b, a
  end
  
  def self.random r, g, b
    return self.new(r * Float.rand(0.2, 0.8), g * Float.rand(0.2, 0.8), b * Float.rand(0.2, 0.8), 1)
  end
  
  def to_a
    return [@r, @g, @b, @a]
  end
end

# some more information about the mark class
class Mark
  alias_method :original, :initialize 
  attr_accessor :gfx
  
  def initialize x, y
    original(x, y)
    @gfx = MarkGFX.new(100+(x)*200,100+((2-y))*200)
    @gfx.mark = self
    #    @things << baaaaam
    #    baaaaam.stone = $game.field[x][y]
  end
end

class Polygon
  def initialize x, y
    @x, @y = x, y
   
    @o = rand(360)
    @r = rand(360)
    @s = 0
  end
  
  attr_accessor :x, :y
  
  def render
    GL.PushMatrix();
    
    GL.Translate(@x,@y,0)
    GL.Rotate(@r,0,0,1)

    GL.Begin(GL::POLYGON)          
    GL.Color(  @c[0].to_a)             
    GL.Vertex3f( -@s, TAN30 * -@s, 0.0)     
    
    GL.Color(  @c[1].to_a)             
    GL.Vertex3f( 0.0, 2*TAN30*@s, 0.0)   
    
    GL.Color(  @c[2].to_a)           
    GL.Vertex3f(@s, TAN30*-@s, 0.0)         
    GL.End()       
    
    GL.PopMatrix();    
  end
  
  def tick dt
    val = - 0.003 * dt
    
    @o += val
    @r += 10*val
    @s = 80 + 10 * Math.sin(@o);
  end
end

class Mouse < Polygon
  def initialize(x, y)
    super
    
    @c = Array.new(3) do Color.random(0, 1, 0) end
    @c.each { |c| c.a = 0.7 }
    
    @d = Array.new(3) do Color.random(0, 0, 0) end
    @d.each { |c| c.a = 0.7 }
  end
  
  def render
    GL.PushMatrix();
    
    GL.Translate(@x,@y,0)
    GL.Rotate(@r,0,0,1)

    GL.Begin(GL::TRIANGLES)          
    GL.Color(  @c[0].to_a)             
    GL.Vertex3f( -@s, TAN30 * -@s, 0.0)     
    
    GL.Color(  @c[1].to_a)             
    GL.Vertex3f( 0.0, 2*TAN30*@s, 0.0)   
    
    GL.Color(  @c[2].to_a)           
    GL.Vertex3f(@s, TAN30*-@s, 0.0)     


    GL.Color(  @d[0].to_a)             
    GL.Vertex3f( -@s/3, TAN30 * -@s/3, 0.0)     
    
    GL.Color(  @d[1].to_a)             
    GL.Vertex3f( 0.0, 2*TAN30*@s/3, 0.0)   
    
    GL.Color(  @d[2].to_a)           
    GL.Vertex3f(@s/3, TAN30*-@s/3, 0.0)
    GL.End()       
    
    GL.PopMatrix();    
  end
  
  @q = 0
  def tick dt
    super
    
    if $game.player == 1
      return if @q == 1
      @q = 1
      @d.each do |a| a.r = 0 end
      @d.each do |a| a.b = Float.rand(0.2, 0.8) end
    else
            return if @q == 2
      @q = 2
      @d.each do |a| a.r = Float.rand(0.2, 0.8) end
      @d.each do |a| a.b = 0 end
    end
  end
end

class MarkGFX < Polygon
  attr_accessor :mark
  
  def render
    return if @mark.nil? or @mark.player == 0
    if @c.nil?
      # @c = Color.random(1, 1, 1)
      if @mark.player == 1
        @c = Array.new(3) do Color.random(1, 0, 0) end
      elsif @mark.player == 2
        @c = Array.new(3) do Color.random(0, 0, 1) end
      end
    end
    super  
  end
  
  def tick dt
    val = 0.003
    unless @mark.nil?
      val = 0.009 if @mark.winner
    end
    
    val *= dt
    
    @o += val
    @r += 10*val
    @s = 80 + 10 * Math.sin(@o);
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
end

def on_key_down key
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
  @m = Mouse.new(200,200)
end

run!

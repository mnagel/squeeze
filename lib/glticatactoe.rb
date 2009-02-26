#!/usr/bin/env ruby -rubygems

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
  end
  
  attr_accessor :x, :y
  
  def render
    tan30 = 0.577
    
    @s = 80 + 10 * Math.sin(@o);
    GL.PushMatrix();
    GL.Translate(@x,@y,0)
    GL.Rotate(@r,0,0,1)

    GL.Begin(GL::POLYGON)          
    GL.Color(  @c[0].to_a)          
    #GL.Vertex3f( -@s, + 2*@s * Math.sin(@o), 0.0)        
    GL.Vertex3f( -@s, tan30 * -@s, 0.0)         
    GL.Color(  @c[1].to_a)            
    #GL.Vertex3f( - @s * Math.sin(@o), + 2*@s + 2*@s * Math.sin(@o), 0.0)   
    GL.Vertex3f( 0.0, 2*tan30*@s, 0.0)   
    GL.Color(  @c[2].to_a)           
    #GL.Vertex3f(+ @s, -@s * Math.sin(@o), 0.0)         
    GL.Vertex3f(@s, tan30*-@s, 0.0)         
    GL.End()       
    GL.PopMatrix();    
  end
  
  def tick dt
    val = - 0.003 * dt
    
    @o += val
    @r += 10*val
  end
end

class Mouse < Polygon
  def initialize(x, y)
    super
    
    @c = Array.new(3) do Color.random(0, 1, 0) end
    @c.each { |c| c.a = 0.7 }
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
  end
end

def draw_gl_scene dt
  axres = XWINRES
  ayres = YWINRES
  
  
      GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,axres,ayres);
  GL::Ortho(0,axres,0,ayres,0,128);
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  GL::MatrixMode(GL::MODELVIEW);

  
  axres = 600
  ayres = 600
  GL::MatrixMode(GL::PROJECTION);
  #GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,YWINRES);
  GL::Ortho(0,axres,0,ayres,0,128);
  GL::MatrixMode(GL::MODELVIEW);
  
  $game.field.each { |x,y,o| o.gfx.render; o.gfx.tick dt }
  
  
    axres = XWINRES
  ayres = YWINRES
  
    GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,axres,ayres);
  GL::Ortho(0,axres,0,ayres,0,128);
  #GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  GL::MatrixMode(GL::MODELVIEW);
  
       GL::Enable(GL::BLEND); GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA);  
    
  @m.tick dt
  @m.render
  
  GL.BindTexture( GL_TEXTURE_2D, 0 );
  # GL::LoadIdentity();
  SDL.GLSwapBuffers
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    $running = false
  elsif event.is_a?(SDL::Event2::KeyDown)
    if event.sym == SDL::Key::ESCAPE
      $running = false
    elsif event.sym == 48 # TODO 48 sucks!
      unless $game.gameover?
        a, b = $game.ki_get_move; 
        $game.do_move(a,b) 
        puts $game.to_s
      end
    elsif event.sym == SDL::Key::SPACE
      $game = TicTacToe.new
      puts $game.to_s
    else puts event.sym
    end
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    if event.button == SDL::Mouse::BUTTON_RIGHT
      $game = TicTacToe.new
      puts $game.to_s
    elsif event.button == SDL::Mouse::BUTTON_LEFT
      fx = (event.x / (XWINRES/3)).to_i
      fy = (event.y / (YWINRES/3)).to_i
      unless $game.gameover?
        $game.do_move(fx,fy) 
        puts $game.to_s
      end
  elsif event.button == SDL::Mouse::BUTTON_MIDDLE
      unless $game.gameover?
        a, b = $game.ki_get_move; 
        $game.do_move(a,b) 
        puts $game.to_s
      end
    end
  elsif event.is_a?(SDL::Event2::MouseMotion)
    @m.x = event.x
    @m.y = YWINRES-event.y
  end
end

def startup
  $game = TicTacToe.new
  puts $game.to_s
  @m = Mouse.new(200,200)
end

run!

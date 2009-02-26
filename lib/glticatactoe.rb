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
  attr_accessor :r, :g, :b
  
  def initialize r, g, b
    @r, @g, @b = r, g, b
  end
  
  def self.random r, b, g
    return self.new(r * Float.rand(0.2, 0.8), b * Float.rand(0.2, 0.8), g * Float.rand(0.2, 0.8))
  end
  
  def to_a
    return [@r, @b, @g]
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
   
    @o = rand
    @r = rand
  end
  
  attr_accessor :x, :y
  
  def render
    tan30 = 0.577
    
    @s = 80 + 10 * Math.sin(@o);
    GL.PushMatrix();
    GL.Translate(@x,@y,0)
    GL.Rotate(@r,0,0,1)

    GL.Begin(GL::POLYGON)          
    GL.Color(  @c.to_a)          
    #GL.Vertex3f( -@s, + 2*@s * Math.sin(@o), 0.0)        
    GL.Vertex3f( -@s, tan30 * -@s, 0.0)         
    GL.Color(  @c.to_a)            
    #GL.Vertex3f( - @s * Math.sin(@o), + 2*@s + 2*@s * Math.sin(@o), 0.0)   
    GL.Vertex3f( 0.0, 2*tan30*@s, 0.0)   
    GL.Color(  @c.to_a)           
    #GL.Vertex3f(+ @s, -@s * Math.sin(@o), 0.0)         
    GL.Vertex3f(@s, tan30*-@s, 0.0)         
    GL.End()       
    GL.PopMatrix();    
  end
  
  def tick
    val = 0.003
    
    @o += val
    @r += 10*val
  end
end

class Mouse < Polygon
  def initialize(x, y)
    super
    
    @c = Color.random(1, 1, 1)
  end
end

class MarkGFX < Polygon
  attr_accessor :mark
  
  def render
    return if @mark.nil? or @mark.player == 0
    if @c.nil?
      @c = Color.random(1, 1, 1)
      if @mark.player == 1
        @c = Color.random(1, 0, 0)
      elsif @mark.player == 2
        @c = Color.random(0, 1, 0)
      end
    end
    super  
  end
  
    def tick
    val = 0.003
    unless @mark.nil?
      val = 0.009 if @mark.winner
    end
    
    @o += val
    @r += 10*val
  end
end

def fps
  $FREQ = 1000
  $frames += 1
  if $frames.modulo($FREQ) == 0
    $timeold = $time
    $time = Time.now
    delta = ($time - $timeold).to_f
    $fps = ($FREQ/delta).to_i
    SDL::WM.setCaption "#{$fps} FPS", ""
  end
end

def draw_gl_scene
  fps
  
  axres = XWINRES
  ayres = YWINRES
  
  GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,axres,ayres);
  GL::Ortho(0,axres,0,ayres,0,128);
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
GL::MatrixMode(GL::MODELVIEW);
  
    
  @m.tick
  @m.render
  
  axres = 600
  ayres = 600
  GL::MatrixMode(GL::PROJECTION);
  #GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,YWINRES);
  GL::Ortho(0,axres,0,ayres,0,128);
  GL::MatrixMode(GL::MODELVIEW);
  
  $game.field.each { |x,y,o| o.gfx.render; o.gfx.tick }
  
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
    puts "nothing yet"
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

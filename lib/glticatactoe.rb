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

class Thing
  def initialize x, y, player=0
    @x = x
    @y = y
    
    if player == 1
      @c1, @c2, @c3 = 0, rand, rand
    elsif player == 2
      @c1, @c2, @c3 = rand, 0, 0
    else
       @c1, @c2, @c3 = rand, rand, rand
    end
    
    
    @o = rand
    @r = rand
  end
  
  attr_accessor :x, :y 
  
  def render
    @s = 30.0
    GL.PushMatrix();
    GL.Translate(@x,@y,0)
    GL.Rotate(@r,0,0,1)

    GL.Begin(GL::POLYGON)          
    GL.Color3f(  @c1, 0.0, 0.0)          
    GL.Vertex3f( -@s, + 2*@s * Math.sin(@o), 0.0)         
    GL.Color3f(  0.0, @c2, 0.0)            
    GL.Vertex3f( - @s * Math.sin(@o), + 2*@s + 2*@s * Math.sin(@o), 0.0)   
    GL.Color3f(  0.0, 0.0, @c3)           
    GL.Vertex3f(+ @s, -@s * Math.sin(@o), 0.0)         
    GL.End()       
    GL.PopMatrix();    
  end
  
  def tick
    @o += 0.003
    @r += 0.03
  end
end

def draw_gl_scene
  $FREQ = 1000
  $frames += 1
  if $frames.modulo($FREQ) == 0
    $timeold = $time
    $time = Time.now
    delta = ($time - $timeold).to_f
    $fps = ($FREQ/delta).to_i
    SDL::WM.setCaption "#{$fps} FPS", ""
  end
  
  aXWINRES = XWINRES
  aYWINRES = YWINRES
  
  GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,aXWINRES,aYWINRES);
  GL::Ortho(0,aXWINRES,0,aYWINRES,0,128);
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)  
    
  @m.tick
  @m.render
  
    @t2.each { |t| 
    t.tick; t.render 
  }

  
  aXWINRES = 400
  aYWINRES = 400
  
  #GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,XWINRES);
  GL::Ortho(0,aXWINRES,0,aYWINRES,0,128);
  #GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)  
  
  @things.each { |t| 
    t.tick; t.render 
  }
  
  GL.BindTexture( GL_TEXTURE_2D, 0 );
  GL::LoadIdentity();
  SDL.GLSwapBuffers
end

def sdl_event event
  if event.is_a?(SDL::Event2::Quit)
    puts $fps
    puts "aaa"
    $stdout.flush
    $running = false
  elsif event.is_a?(SDL::Event2::KeyDown)
    if event.sym == SDL::Key::ESCAPE
      puts $fps
      puts "aaa"
      $stdout.flush
      $running = false
    elsif event.sym == 48
      a,b=$game.kiGetMove; $game.doMove(a,b)
      xx,yy=a,b
      @things << Thing.new(50+xx*100,50+(2-yy)*100, $game.field[xx][yy])
    else puts event.sym
    end
  elsif event.is_a?(SDL::Event2::MouseButtonDown)
    @t2 << Thing.new(event.x, YWINRES-event.y) if event.button == SDL::Mouse::BUTTON_LEFT
    @m.recolor if event.button == SDL::Mouse::BUTTON_RIGHT
  elsif event.is_a?(SDL::Event2::MouseMotion)
    @m.x = event.x
    @m.y = YWINRES-event.y
  end
end

require 'tictactoe'
$game = TicTacToe.new
4.times do a,b=$game.kiGetMove; $game.doMove(a,b) end
puts $game.to_s
@m = Thing.new(200,200)#Thing.new(200,200)
@things = []
@t2 = []



for xx in 0..2 do
  for yy in 0..2 do
    @things << Thing.new(50+xx*100,50+(2-yy)*100, $game.field[xx][yy]) if $game.field[xx][yy] != 0
  end
end



#@things = []

#$game.field.each { |i| puts i; puts i.to_s }

#0.upto 2 do |yy|
#  0.upto 2 do |xx|
#    unless $game.field[xx][2-yy] == 0
#      puts "x is #{xx}"
#      puts "y is #{yy}"
# #     puts "value is #{$game.field[xx][yy]}"
#      
##      
#      @things << Thing.new(50+yy*100,50+yy*100)
#    end
#  end
#end

require 'glbase'

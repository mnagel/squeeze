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


class Exception
  def show
    STDERR.puts "there was an error: #{self.message}"
    STDERR.puts self.backtrace
  end
end

XWINRES = 750
YWINRES = 750
FULLSCREEN = 0

def init_gl_window(width = XWINRES, height = YWINRES)
  GL::Viewport(0,0, width, height)
  # Background color to black
  GL::ClearColor(0.0, 0.0, 0.0, 0)
  # Enables clearing of depth buffer
  GL::ClearDepth(1.0)
  # Set type of depth test
  GL::DepthFunc(GL::LEQUAL)
  # Enable Textures
  GL::Enable(GL::TEXTURE_2D)
  # Enable depth testing
  GL::Enable(GL::DEPTH_TEST)
  # Enable smooth color shading
  GL::ShadeModel(GL::SMOOTH)
  GL::MatrixMode(GL::PROJECTION)
  GL::LoadIdentity()
  # Calculate aspect ratio of the window
  GLU::Perspective(60.0, width / height, 0.1, 100.0)
  GL::MatrixMode(GL::MODELVIEW)
end

def define_screen virtual_x = XWINRES, virtual_y  = YWINRES
  GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,YWINRES);
  GL::Ortho(0,virtual_x,0,virtual_y,0,128);
  GL::MatrixMode(GL::MODELVIEW);
end


def drawtext font, r, g, b, x, y, z, text

  GL.Color( r,g,b) 
  
  GL.PushMatrix();
  GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,YWINRES);
  GL::Ortho(0,XWINRES,YWINRES,0,0,128);
  GL::MatrixMode(GL::MODELVIEW);
  

  surface = font.renderBlendedUTF8(text,r,g, b); # dont generate over and over again
 
  $texture = GL.GenTextures(1).first;  # dont generate over and over again...
  GL::BindTexture(GL::TEXTURE_2D, $texture);
 
  GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
  GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
 
  GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, surface.w, surface.h, 0, GL::BGRA, GL::UNSIGNED_BYTE, surface.pixels);
 
  
  GL::Begin(GL_QUADS);
  GL.TexCoord2d(0, 0); GL.Vertex3d(x, y, z);
  GL.TexCoord2d(1, 0); GL.Vertex3d(x+surface.w, y, z);
  GL.TexCoord2d(1, 1); GL.Vertex3d(x+surface.w, y+surface.h, z);
  GL.TexCoord2d(0, 1); GL.Vertex3d(x, y+surface.h, z);
  GL::End();
        
  GL::BindTexture(GL::TEXTURE_2D,0);


  GL::DeleteTextures($texture)
  
  GL.PopMatrix();
end

$dt = 100
$oldt = Time.now
def fps
  time = Time.now
  $dt = 1000 * (time - $oldt).to_f
  $oldt = time
  
  #puts $dt
  
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

def run!
  SDL.init(SDL::INIT_VIDEO)
  SDL::TTF.init

  $frames = 0
  $time = Time.now
  $font = SDL::TTF.open("font.ttf", 20, index = 0)
  
  SDL.setVideoMode(XWINRES, YWINRES, 0, (SDL::FULLSCREEN * FULLSCREEN)|SDL::OPENGL|SDL::HWSURFACE)
  init_gl_window(XWINRES, YWINRES)
  SDL::Mouse.hide()
  
  startup
  GL.BindTexture( GL_TEXTURE_2D, 0 );
  
  $running = true
  while $running do
    event = SDL::Event2.poll
    if !event.nil?
      sdl_event(event)
    end
    fps
    GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    draw_gl_scene $dt
    
    SDL.GLSwapBuffers
  end
end

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

XWINRES = 800
YWINRES = 600
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

def initstuff
  big_endian = ([1].pack("N") == [1].pack("L"))

  if big_endian
    rmask = 0xff000000
    gmask = 0x00ff0000
    bmask = 0x0000ff00
    amask = 0x000000ff
  else
    rmask = 0x000000ff
    gmask = 0x0000ff00
    bmask = 0x00ff0000
    amask = 0xff000000
  end
  
  w = 256         # pow(2,ceil(log(ourSurface->w)/log(2))); /* round up to the nearest power of two*/
  sdltext = $font.renderBlendedUTF8("testrendering",100, 100, 100);
  sdltexture = SDL::Surface.new(SDL::SWSURFACE, w, w, 32, rmask, gmask, bmask, amask);
  SDL::Surface.blit(sdltext, 0, 0, w, w, sdltexture, 0, 0)
  
  $texture = GL.GenTextures(1).first;
  GL.BindTexture( GL_TEXTURE_2D, $texture );
  
  GL.TexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
  GL.TexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
  
  GL.TexImage2D( GL::TEXTURE_2D, 0, 4, sdltexture.w, sdltexture.h, 0, GL::RGBA, GL::UNSIGNED_BYTE, sdltexture.pixels );
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
  
  
  initstuff
  
  startup
  
  $running = true
  while $running do
    event = SDL::Event2.poll
    if !event.nil?
      sdl_event(event)
    end
    draw_gl_scene
  end
end

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


XWINRES = 750
YWINRES = 750
FULLSCREEN = 0

require "sdl"
require "opengl"

def with_some_matrix
  GL.PushMatrix();
  yield if block_given?
  GL.PopMatrix();
end

class Color
  attr_accessor :r, :g, :b, :a
  
  def initialize r, g, b, a=1
    @r, @g, @b, @a = r, g, b, a
  end
  
  def self.random r, g, b, a = 1
    offset = 0.2
    return self.new(
      r * (offset + Float.rand(0.2, 0.8)), 
      g * (offset + Float.rand(0.2, 0.8)), 
      b * (offset + Float.rand(0.2, 0.8)), 
      a)
  end
  
  def to_a
    return [@r, @g, @b, @a]
  end
end

class Entity
  def initialize x, y, size
    @x, @y, @size = x, y, size
    
    @subs = []
    @visible = true
  end
  
  attr_accessor :x, :y, :size, :visible
  attr_reader :subs
  
  def render
    with_some_matrix do
      GL.Translate(@x, @y, 0)
      GL.Scale(@size,@size,1)
    
      yield if block_given?
  
      @subs.each { |sub| sub.render }
      
    end if @visible
  end
  
  def tick dt
    @subs.each { |sub| sub.tick dt }
  end
end

class OpenGLPrimitive < Entity
  def initialize x, y, size
    super x, y, size
    @max_size = size
    
    @rotation = 0
    @pulse = 0
    @rotating = false
    @pulsing = false
  end
  
  def rotating=(bool)
    puts "setting rotation to #{bool} for #{self.class}"
    @rotating = bool
  end
  
  def pulsing=(bool)
    @pulsing = bool
  end
  
  attr_reader :pulsing
  
  def tick dt
    super dt
    val = 0.003 * dt
    
    @rotation += 10 * val if @rotating
    @pulse += val if @pulsing
    sin = Math.cos(@pulse)
    @size = @max_size * 0.5 * (1 + sin * sin)
  end
  
  def render
    with_some_matrix do
      super do
        GL.Rotate(@rotation, 0, 0, 1)
        yield if block_given?
      end
    end
  end
end

class Triangle < OpenGLPrimitive
  # TODO wie geht das mit den :var => value zuweisungen
  def initialize x, y, size, colors
    super x, y, size
    @colors = colors
    unless (@colors.is_a?(Array) and @colors.length == 3)
      STDERR.puts Exception.new("@colors should be set properly, was #{@colors} when initin #{self}")
      @colors = Array.new(4) do Color.new(255, 255, 0, 1) end
    end
    #    end
  end
  
  attr_accessor :colors
  
  def render
    super do
      GL.Begin(GL::TRIANGLES)
      GL.Color(@colors[0].to_a)
      GL.Vertex3f(-1, -TAN30, 0.0)
    
      GL.Color(@colors[1].to_a)
      GL.Vertex3f(0, 2*TAN30, 0.0)
    
      GL.Color(@colors[2].to_a)
      GL.Vertex3f(1, -TAN30, 0.0)
      GL.End()       
    end
  end
end

class Square < OpenGLPrimitive
  # TODO wie geht das mit den :var => value zuweisungen
  def initialize x, y, size, colors
    super x, y, size
    @colors = colors
    unless (@colors.is_a?(Array) and @colors.length == 4)
      STDERR.puts Exception.new("@colors should be set properly, was #{@colors} when initin #{self}") 
      @colors = Array.new(3) do Color.new(255, 255, 0, 1) end
    end
  end
  
  attr_accessor :colors, :gltexture
  
  def render
    super do
      unless @gltexture.nil?
        GL::Enable(GL::TEXTURE_2D)
        GL::BindTexture(GL::TEXTURE_2D, @gltexture);
      
        GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
        GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
      end
      
      GL::Begin(GL_QUADS);
      GL.Color(@colors[0].to_a);
      GL.TexCoord2d(0, 1); GL.Vertex3d(-1, +1, 0) unless @gltexture.nil?
      GL.Color(@colors[1].to_a);
      GL.TexCoord2d(1, 1); GL.Vertex3d(+1, +1, 0) unless @gltexture.nil?
      GL.Color(@colors[2].to_a);
      GL.TexCoord2d(1, 0); GL.Vertex3d(+1, -1, 0) unless @gltexture.nil?
      GL.Color(@colors[3].to_a);
      GL.TexCoord2d(0, 0); GL.Vertex3d(-1, -1, 0) unless @gltexture.nil?
      GL::End();
      unless @gltexture.nil?
        GL::BindTexture(GL::TEXTURE_2D, 0);
        GL::Disable(GL::TEXTURE_2D)
      end
    end
  end
end

class Texture
  def initialize filename
    #@colors = Array.new(4) do colors end
    
    @sdlsurface = SDL::Surface.load(filename)  # TODO catch non-rgba-png errors
    
    @gltexture = GL.GenTextures(1).first;  # dont generate over and over again...
    GL::BindTexture(GL::TEXTURE_2D, @gltexture);
    
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
    
    GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, @sdlsurface.w, @sdlsurface.h, 0, 
      GL::RGBA, GL::UNSIGNED_BYTE, @sdlsurface.pixels);
    
    @w = @sdlsurface.w
    @h = @sdlsurface.h
    
    @handle = @gltexture
    
    # TODO SDL Surface direkt freigeben    
    # TODO im FINALIZER
    # GL::DeleteTextures($texture)
  end
  
  attr_reader :handle, :w, :h
end

class Picture < Square
  # TODO allow NON-square pictures!
  # TODO wie geht das mit den :var => value zuweisungen
  def initialize filename, x, y, size, colors
    super x, y, size * 0.5, colors
    #@colors = Array.new(4) do colors end
    
    @sdlsurface = SDL::Surface.load(filename)  # TODO catch non-rgba-png errors
    
    @gltexture = GL.GenTextures(1).first;  # dont generate over and over again...
    GL::BindTexture(GL::TEXTURE_2D, @gltexture);
    
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
    
    GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, @sdlsurface.w, @sdlsurface.h, 0, 
      GL::RGBA, GL::UNSIGNED_BYTE, @sdlsurface.pixels);
    
    @w = @sdlsurface.w
    @h = @sdlsurface.h
    
    # TODO SDL Surface direkt freigeben    
    # TODO im FINALIZER
    # GL::DeleteTextures($texture)
  end   
end

# TODO : inherit from Texturized Rectangle
# TODO : introduce "colored primitive" class
class Text < OpenGLPrimitive
  
  SDL::TTF.init
  SDL.init(SDL::INIT_VIDEO)
  
  def initialize x, y, size, color, font, text
    super x, y, size
    @color = color
    @font = SDL::TTF.open(font, 20, index = 0)
    set_text text
  end
  
  def set_text(string)
    return if @text == string
    @text = string
    @sdlsurface = @font.renderBlendedUTF8(string, @color.r, @color.g, @color.b) # TODO need power of two?
    @w = @sdlsurface.w
    @h = @sdlsurface.h
    # puts "size is #{@w}x#{@h}"
    @gltexture = GL.GenTextures(1).first;
    
    STDERR.puts "really, really check if you are allocating textures correctly. are you trying to
      create them before init of sdl/opengl has finished?!?" if @gltexture > 3000000
    STDERR.puts "ERRRRRRRRRRRRROR" if GL.GetError != 0
    
    GL::BindTexture(GL::TEXTURE_2D, @gltexture);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
  
    GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, @sdlsurface.w, @sdlsurface.h, 0, 
      GL::BGRA, GL::UNSIGNED_BYTE, @sdlsurface.pixels)
  end
  
  attr_reader :gltexture
  
  def render
    super do
      GL::Enable(GL::TEXTURE_2D)
      with_some_matrix do
        GL::BindTexture(GL::TEXTURE_2D, @gltexture);
        GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
        GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
      
        h, w = 1, @w.to_f/@h.to_f
    
        GL::Color(@color.to_a)
        GL::Begin(GL_QUADS);
        GL.TexCoord(0, 1); GL.Vertex(0, 0, 0);
        GL.TexCoord(1, 1); GL.Vertex(w, 0, 0);
        GL.TexCoord(1, 0); GL.Vertex(w, h, 0);
        GL.TexCoord(0, 0); GL.Vertex(0, h, 0);
        GL::End();
    
        GL::BindTexture(GL::TEXTURE_2D,0);
      end
      GL::Disable(GL::TEXTURE_2D)
    end
  end
end

class Exception
  def show
    STDERR.puts "there was an error: #{self.message}"
    STDERR.puts self.backtrace
  end
end

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

def define_screen virtual_x = XWINRES, virtual_y = YWINRES
  GL::MatrixMode(GL::PROJECTION);
  GL::LoadIdentity();
  GL::Viewport(0,0,XWINRES,YWINRES);
  GL::Ortho(0,virtual_x,0,virtual_y,0,128);
  GL::MatrixMode(GL::MODELVIEW);
end

class Timer
  def initialize
    @last_tick = @rate_tick = Time.now
    @tickcount = 0
    @tickrate = 60
    @running = true
    @total_time = 0.0
    @to_call = []
    @UPDATERATE = 120 # ticks
  end
  
  attr_reader :running
  
  def tick
    time = Time.now
    delta = @running ? 1000 * (time - @last_tick).to_f : 0.0
    @last_tick = time
    @tickcount += 1
    
    if @tickcount.modulo(@UPDATERATE) == 0
      delta2 = (@last_tick - @rate_tick).to_f
      @rate_tick = @last_tick
      @tick_rate = (@UPDATERATE / delta2).to_i
    end
    
    @to_call.delete_if { |item| 
      if item.first < @total_time
        item.last.call
        true
      else
        false
      end      
    }
    
    @total_time += delta
    return delta  
  end
  
  def call_later(delta, &block)
    @to_call << [@total_time + delta, block]
  end
  
  def ticks_per_second
    return @tick_rate
  end
  
  def toggle
    @running ? pause : resume
  end
  
  def pause
    @running = false
  end
  
  def resume
    @running = true
    @last_tick = Time.now
  end
end

class Engine
  attr_accessor :running, :timer
  
  def initialize
    @running = true
    @timer = Timer.new
    
    SDL.setVideoMode(XWINRES, YWINRES, 0,
      (SDL::FULLSCREEN * FULLSCREEN)|SDL::OPENGL|SDL::HWSURFACE)
    
    init_gl_window(XWINRES, YWINRES)
    SDL::Mouse.hide()
  end
  
  # all stuff ready
  def prepare 
    
  end
  
  def run!
    while @running do
      until (event = SDL::Event2.poll).nil?
        sdl_event(event)
      end
      
      GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
      draw_gl_scene @timer.tick
      
      SDL.GLSwapBuffers
    end
  end
  
  def kill!
    @running = false
  end
end


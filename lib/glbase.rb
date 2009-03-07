#!/usr/bin/env ruby -wKU


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

# TODO finalizers, private attributes, getters, setters ...
# TODO document!!!

class Color
  def r
    @data[0]
  end
  
  def g
    @data[1]
  end
  
  def b
    @data[2]
  end
  
  def a
    @data[3]
  end
  
  def r=val
    @data[0] = val
  end
  
  def g=val
    @data[1] = val
  end
  
  def b=val
    @data[2] = val
  end
  
  def a=val
    @data[3] = val
  end
  
  def initialize r, g, b, a=1
    @data = [r, g, b, a]
  end
  
  def self.random r, g, b, a=1
    min =     0.2
    max = 1 - min
    return self.new(
      r * (min + Float.rand(min, max)), 
      g * (min + Float.rand(min, max)), 
      b * (min + Float.rand(min, max)), 
      a)
  end
  
  def as_a
    return @data
  end
end

class ColorList
  attr_accessor :vals
  
  def initialize len, &code
    @vals = Array.new(len) do |index| code.call(index) end
    if len < 3 and
        puts "WARNING, you dont want to have a color-list this short..."
      begin
        throw Exception.new
      rescue => e
        # e.show
      end
    end
  end
  
  def as_a
    return @vals
  end
end

class Texture
  attr_accessor :gl_handle, :w, :h
  
  def kill!
    GL.DeleteTextures @gl_handle
  end
  
  # TODO : remember to call kill!() at the end -- have it have some kind of finalizer
  def initialize handle, w, h
    @gl_handle, @w, @h = handle, w, h
  end
  
  def self.load_file filename
    sdlsurface = SDL::Surface.load(filename)  # TODO catch non-rgba-png errors
    
    my_gl_handle = GL.GenTextures(1).first;  # dont generate over and over again...
    GL::BindTexture(GL::TEXTURE_2D, my_gl_handle);
    
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
    
    GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, sdlsurface.w, sdlsurface.h, 0, 
      GL::RGBA, GL::UNSIGNED_BYTE, sdlsurface.pixels);
    
    my_w, my_h = sdlsurface.w, sdlsurface.h
    
    return self.new(my_gl_handle, my_w, my_h)
    
    # TODO im FINALIZER # GL::DeleteTextures($texture)
  end
  
  def self.render_text string, font 
    sdlsurface = font.renderBlendedUTF8(string, 255, 255, 255) # white, because color is set in opengl afterwards
    my_gl_handle = GL.GenTextures(1).first;
    
    STDERR.puts "really, really check if you are allocating textures correctly. are you trying to
      create them before init of sdl/opengl has finished?!?" if my_gl_handle > 3000000
    STDERR.puts "ERRRRRRRRRRRRROR" if GL.GetError != 0
    
    GL::BindTexture(GL::TEXTURE_2D, my_gl_handle);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
    GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
  
    GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, sdlsurface.w, sdlsurface.h, 0, 
      GL::BGRA, GL::UNSIGNED_BYTE, sdlsurface.pixels)
    
    my_w, my_h = sdlsurface.w, sdlsurface.h
    return self.new(my_gl_handle, my_w, my_h)
  end
  
  @@none = self.new(0, 0, 0)
  def self.none
    return @@none
  end
end

class Entity
  attr_accessor :x, :y, :z, :w, :h, :r, :parent, :subs, :visible
  
  def initialize x, y, w, h
    @x, @y, @w, @h = x, y, w, h
    @z = 0
    @r = 0
    
    @visible = true
    @parent = nil
    @subs = []
  end
  
  def tick dt
    @subs.each do |sub| sub.tick dt end
    # puts "ticking" if is_a?(Mouse)
  end
  
  def render
    with_some_matrix do
      if @colors.nil?
        puts "WARNING: @color == nil for #{self}, resetting"
        @colors = ColorList.new(4) { |i| Color.new(1.0, 0, 1.0, 0.8) }
      end
      translate; scale; rotate;
      yield if block_given?      
      @subs.each do |sub| sub.render end
    end if @visible
  end
  
  def translate
    GL.Translate(@x, @y, @z)
  end
  
  def scale
    GL.Scale(@w, @h, 1)
  end
  
  def rotate
    GL.Rotate(@r,0,0,1)
    # puts "rotated #{@r}" if is_a?(Mouse)
  end
  
  def addsub sub
    @subs << sub
    sub.parent = self
  end
end

class OpenGL2D < Entity
  attr_accessor :colors, :texture
  
  def initialize x, y, w, h
    super x, y, w, h
    # @colors = nil
    # @colors = ColorList.new(4) { |i| Color.random(1.0, 1.0, 1.0, 1.0) }
    # puts "Warning, generating random color!"
    # @colors = 
    @texture = Texture.none
  end
end

class Rect < OpenGL2D
  def render
    super do
      #unless @gltexture.nil?
      GL::Enable(GL::TEXTURE_2D)
      GL::BindTexture(GL::TEXTURE_2D, @texture.gl_handle);
      
      GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR);
      GL::TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR);
      #end
      
      GL::Begin(GL_QUADS);
      GL.Color(@colors.as_a[0].as_a);
      GL.TexCoord2d(0, 1); GL.Vertex3d(-1, +1, 0) # unless @texture.nil?
      GL.Color(@colors.as_a[1].as_a);
      GL.TexCoord2d(1, 1); GL.Vertex3d(+1, +1, 0) # unless @texture.nil?
      GL.Color(@colors.as_a[2].as_a);
      GL.TexCoord2d(1, 0); GL.Vertex3d(+1, -1, 0) # unless @texture.nil?
      GL.Color(@colors.as_a[3].as_a);
      GL.TexCoord2d(0, 0); GL.Vertex3d(-1, -1, 0) # unless @texture.nil?
      GL::End();
      #unless @texture.nil?
      GL::BindTexture(GL::TEXTURE_2D, 0);
      GL::Disable(GL::TEXTURE_2D)
      #end
    end
  end
end

class Square < Rect
  def initialize x, y, size
    super x, y, size, size
  end
end

class Triangle < OpenGL2D
  def render
    super do
      
      GL.Begin(GL::TRIANGLES)
      GL.Color(@colors.as_a[0].as_a)
      GL.Vertex3f(-1, -TAN30, 0.0)
      
      GL.Color(@colors.as_a[1].as_a)
      GL.Vertex3f(0, 2*TAN30, 0.0)
      
      GL.Color(@colors.as_a[2].as_a)
      GL.Vertex3f(1, -TAN30, 0.0)
      GL.End()       
    end
  end
end

MYVAL = 40
MYVAL2 = 3

class Text < Rect
  
  private
  
  public
  
  attr_reader :text
  
  def set_text text
    @texture.kill! unless @texture.nil?
    # re render texture
    @texture = Texture.render_text(text, @font)
    @h, @w = 1, 1 # @texture.w.to_f/@texture.h.to_f # FIXME!!!
    
    @w = @texture.w * @size / (MYVAL * MYVAL2) #size
    @h = @texture.h  * @size / (MYVAL * MYVAL2) #size
  end
  
  def initialize x, y, size, color, font, text
    @color = color
    @size = size
    @colors = ColorList.new(4) { |i| color }
    @font = SDL::TTF.open(font, MYVAL, index = 0)
    @texture = nil
    set_text text
    t = @texture
    super x, y, @w, @h
    @texture = t
    #puts "@w is #{@w}, @h is #{@h}"
    
    @w = @texture.w* @size / (MYVAL * MYVAL2)  #size
    @h = @texture.h * @size / (MYVAL * MYVAL2)#size
    #
    #puts "@w is #{@w}, @h is #{@h}"
    #@w = @texture.w
    #@h = @texture.h
  end
end

module Rotating
  def tick dt
    super
    val = 0.003 * dt
    
    @r += 10 * val if @rotating
    # puts "rotating"
  end
end

module Pulsing
  
  def reinit # FIXME auto-call in include/extend
    @pulse = 0
    @pulsing = true
    @max_h = @h
    @max_w = @w
  end
    
  def tick dt

    super
    return unless @pulsing
    val = 0.003 * dt
      
    @pulse += val
    sin = Math.cos(@pulse)
    #puts "sin #{sin}, @max_w #{@max_w}, @max_h #{@max_h}"
    @w = @max_w * 0.5 * (1 + sin * sin)
    @h = @max_h * 0.5 * (1 + sin * sin)
  end
    
  attr_accessor :pulse, :pulsing
end
  
module TopLeftPositioning
  def translate
    super
    GL.Translate(@w, @h, 0)
  end
end

XWINRES = 750
YWINRES = 750
FULLSCREEN = 0
TITLE = "gl base supported application"

require "sdl"
require "opengl"

  
SDL::TTF.init
SDL.init(SDL::INIT_VIDEO)


def with_some_matrix
  GL.PushMatrix();
  yield if block_given?
  GL.PopMatrix();
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
  GL::Ortho(0,virtual_x,virtual_y,0,0,128);
  GL::MatrixMode(GL::MODELVIEW);
end

class Timer
  def initialize
    @last_tick = @rate_tick = Time.now
    @tickcount = 0
    @tick_rate = 60
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
  
  def wipe! call_all = true
    @to_call.each { |item| item.last.call } if call_all
    @to_call.clear
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
    SDL::WM.setCaption(TITLE, "")
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


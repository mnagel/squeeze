#!/usr/bin/env ruby -wKU


=begin
    glgames - framework for some opengl games using ruby
    Copyright (C) 2009 by Michael Nagel

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

=end

# TODO add rdoc to svn/website # create into ignored dir (building deletes svn stuff...)
# and have script to copy it over to final location
# TODO prepare for ruby 1.9
# TODO offer debug mode that annotates objects with status information (like the bounding boxes)
# TODO use finalizers, private attributes, getters, setters ...
# TODO document code
# TODO customizable screen size, port code from squeeze
# TODO render at 60hz/second but update physics more often

# base class of the classes that save settings...
class SettingsBase
  # x size of the window
  attr_accessor :winX
  # y size of the window
  attr_accessor :winY
  # window is fullscreen true/false
  attr_accessor :fullscreen
  # title for the window
  attr_accessor :win_title
  # should fps be displayed
  attr_accessor :show_fps
  
  # after how many frames should the fps be calculated # TODO change this to be based on time, not frames
  attr_accessor :updaterate
  # how big freetype should render
  attr_accessor :freetype_fontsize
  # resizing freetype hack
  attr_accessor :freetype_adjustment_hack
  # path to file with font to use
  attr_accessor :fontfile

  # sets the default settings
  def initialize
    @winX = 750
    @winY = 750
    @fullscreen = 0
    @show_fps = true

    @win_title = "gl base supported application"
    @updaterate = 120 # ticks

    @freetype_fontsize = 60
    @freetype_adjustment_hack = 3
    @fontfile = get_fontpath
  end

  # returns the path of the font file to use by checking some "well known places"
  def get_fontpath
    ps = ["/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf",
      "/usr/share/fonts/bitstream-vera/Vera.ttf",
      "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf"
    ]

    ps.each { |item|
      return item if FileTest.exists?(item)
    }

    throw "cannot find font file. looked at #{ps.join(" ")}"
  end
end

require 'v_math';
V = Math::V2

silently do require 'sdl' end
require 'opengl'
require 'logger'

# TODO check if 0..1 or 0..255 scaled...
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

class << Math
  def log2(n)
    log(n) / log(2)
  end
end

def ceil_to_power_of_2 int
  2**(Math.log2(int).ceil)
end

class Texture
  attr_accessor :gl_handle, :size, :content_rect # content rect: 0..1-normalized rect of actual content in texture
  
  def kill!
    GL.DeleteTextures @gl_handle
  end
  
  # TODO remember to call kill!() at the end -- let it have some kind of finalizer
  def initialize handle, w, h, wmax = 1.0, hmax = 1.0
    @size = V.new
    @gl_handle, @size.x, @size.y = handle, w, h
    @content_rect = V.new(wmax,hmax)
  end

  def self.from_sdl_surface surf, swapcolors = false
    my_gl_handle = GL.GenTextures(1).first;
    
    STDERR.puts "really, really check if you are allocating textures correctly. are you trying to
      create them before init of sdl/opengl has finished?!?" if my_gl_handle > 3000000
    STDERR.puts "ERRRRRRRRRRRRROR" if GL.GetError != 0
    
    GL::BindTexture(GL::TEXTURE_2D, my_gl_handle);

    val = swapcolors ? GL::BGRA : GL::RGBA
    myw = ceil_to_power_of_2(surf.w)
    myh = ceil_to_power_of_2(surf.h)

    surf2 = surf.copyRect(0,0,myw,myh)

    begin
      GL::TexImage2D(GL::TEXTURE_2D, 0, GL::RGBA, myw, myh, 0,
        val, GL::UNSIGNED_BYTE, surf2.pixels)

      GL::TexParameter(GL::TEXTURE_2D,GL::TEXTURE_MIN_FILTER,GL::NEAREST);
      GL::TexParameter(GL::TEXTURE_2D,GL::TEXTURE_MAG_FILTER,GL::LINEAR);

    rescue => e
      STDERR.puts "texture could not be created from SDL surface"
      STDERR.puts "#{GL.GetError}"
      e.show
    end

    # report size and actually used fraction
    my_w, my_h = surf2.w, surf2.h
    return self.new(my_gl_handle, my_w, my_h, surf.w/myw.to_f, surf.h/myh.to_f)
  end
  
  def self.load_file filename
    begin
      sdlsurface = SDL::Surface.load(filename)
      return self.from_sdl_surface(sdlsurface, false)
    rescue => exc
      STDERR.puts("#{filename} could not be loaded as texture as expected")
      return self.none
    end
  end
  
  def self.render_text string, font 
    sdlsurface = font.renderBlendedUTF8(string, 255, 255, 255) # white, because color is set in opengl afterwards
    return self.from_sdl_surface(sdlsurface, true)
  end
  
  @@none = self.new(0, 0, 0)
  def self.none
    return @@none
  end
end

class Entity
  attr_accessor :pos, :size, :r, :parent, :subs, :visible, :z # :x, :y, :z, :w, :h,
  
  def initialize x, y, w, h
    @z = 0
    @r = 0
    @pos  = V.new(x, y)
    @size = V.new(w, h)
    
    @visible = true
    @parent = nil
    @subs = []
  end
  
  def tick dt
    @subs.each do |sub| sub.tick dt end
  end
  
  def render
    with_some_matrix do
      if @colors.nil?
        puts "WARNING: @color == nil for #{self}, resetting"
        @colors = ColorList.new(4) { |i| Color.new(1.0, 1.0, 1.0, 0.8) }
      end
      translate; scale; rotate;

      yield if block_given?      
      @subs.each do |sub| sub.render end


      draw_bounding_box if Settings.show_bounding_boxes

    end if @visible
  end

  def draw_bounding_box
    GL::LineWidth(1)
    @c = [1,0,0,1]
    GL.Color(@c)
    GL.Begin(GL::LINE_LOOP)

    GL.Vertex3f( -1, -1, 0.0)
    GL.Vertex3f( -1, +1, 0.0)
    GL.Vertex3f( +1, +1, 0.0)
    GL.Vertex3f( +1, -1, 0.0)

    GL.Vertex3f( -1, -1, 0.0)

    GL.End()


    @c = [0,1,0,1]
    GL.Color(@c)
    GL.Begin(GL::LINE_LOOP);
    angle = 0
    while angle <= 2 * Math::PI

      GL.Vertex3f(Math.cos(angle), Math.sin(angle), 0);

      angle += Math::PI / 30
    end

    GL.End()
  end

  def translate
    GL.Translate(pos.x, pos.y, z) # TODO check the z
  end

  def scale
    GL.Scale(size.x, size.y, 1)
  end

  def rotate
    GL.Rotate(r,0,0,1)
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
    @texture = Texture.none
  end
end

# TODO add line class

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
      GL.Color(@colors.as_a[0].as_a); # TODO explain what content_rect is
      GL.TexCoord2d(0, @texture.content_rect.y); GL.Vertex3d(-1, +1, 0) # unless @texture.nil?
      GL.Color(@colors.as_a[1].as_a);
      GL.TexCoord2d(@texture.content_rect.x, @texture.content_rect.y); GL.Vertex3d(+1, +1, 0) # unless @texture.nil?
      GL.Color(@colors.as_a[2].as_a);
      GL.TexCoord2d(@texture.content_rect.x, 0); GL.Vertex3d(+1, -1, 0) # unless @texture.nil?
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

  @@TAN30 = Math::tan(30 * Math::PI / 180)

  def render
    super do
      
      GL.Begin(GL::TRIANGLES)
      GL.Color(@colors.as_a[0].as_a)
      GL.Vertex3f(-1, -@@TAN30, 0.0)
      
      GL.Color(@colors.as_a[1].as_a)
      GL.Vertex3f(0, 2*@@TAN30, 0.0)
      
      GL.Color(@colors.as_a[2].as_a)
      GL.Vertex3f(1, -@@TAN30, 0.0)
      GL.End()       
    end
  end
end

# TODO allow multiline text...
class Text < Rect
  attr_reader :text
  
  def set_text text
    text = " " if text.nil? or text.length < 1
    return if (text == @text)
    @text = text
    @texture.kill! unless @texture.nil?
    # re render texture
    @texture = Texture.render_text(text, @font)
    @size = V.new
    @size.y, @size.x = 1, 1 # FIXME explain the magic numbers
    
    @size.x = @texture.size.x * @fontsize / (Settings.freetype_fontsize * Settings.freetype_adjustment_hack) #size
    @size.y = @texture.size.y  * @fontsize / (Settings.freetype_fontsize * Settings.freetype_adjustment_hack) #size
  end
  
  def initialize x, y, fontsize, color, font, text
    @text = "this_is_a_text_to_never_match_)@(3"
    @color = color
    @fontsize = fontsize
    @colors = ColorList.new(4) { |i| color }
    @font = nil
    begin

      @font = SDL::TTF.open(font, Settings.freetype_fontsize, index = 0)
      throw "font did not load" if @font.nil?
    rescue => exc
      throw "error opening font: #{font}"
    end
    @texture = nil
    set_text text
    t = @texture
    super x, y, @size.x, @size.y
    @texture = t
    
    @size.x = @texture.size.x* @fontsize / (Settings.freetype_fontsize * Settings.freetype_adjustment_hack)
    @size.y = @texture.size.y * @fontsize / (Settings.freetype_fontsize * Settings.freetype_adjustment_hack)
  end
end

module Rotating
    def self.extend_object(o)
    super
    o.instance_eval do
      @rotating = false
    end # sneak in the rotating AUTOMATICALLY...
  end

  def tick dt
    super; return unless @rotating
    
    @r += 0.03 * dt 
  end
end

module Pulsing
  def self.extend_object(o)
    super
    o.instance_eval do
      @pulse = 0
      @pulsing = true
      @max_h = @size.y
      @max_w = @size.x
    end # sneak in the v AUTOMATICALLY...
  end
    
  def tick dt
    super; return unless @pulsing
 
    @pulse += 0.003 * dt
    sin = Math.cos(@pulse)
    @size.x = @max_w * 0.5 * (1 + sin * sin)
    @size.y = @max_h * 0.5 * (1 + sin * sin)
  end
    
  attr_accessor :pulse, :pulsing
end
  
module TopLeftPositioning
  def translate
    super
    GL.Translate(@size.x, @size.y, 0)
  end
end

SDL::TTF.init
SDL.init(SDL::INIT_VIDEO | SDL::INIT_AUDIO)


def with_some_matrix
  # test with removing the pushes/pops and manually unrotating, scaling, translating
  # the matrix showed no faster execution speeds.
  return unless block_given?
  GL.PushMatrix();
  yield # if block_given?
  GL.PopMatrix();
end

class Exception
  def show
    STDERR.puts "there was an error: #{self.message}"
    STDERR.puts self.backtrace
  end
end

class Timer
  def initialize
    @running = true
    @last_tick = @tick_rate_ref = Time.now
    @tick_count = 0
    @tick_rate = 60
    @total_time = 0.0
    @hooks = []
  end
  
  attr_reader :running
  
  def tick
    time = Time.now
    delta = @running ? 1000 * (time - @last_tick).to_f : 0.0
    @last_tick = time
    @tick_count += 1
    
    if @tick_count.modulo(Settings.updaterate) == 0
      delta2 = (@last_tick - @tick_rate_ref).to_f
      @tick_rate_ref = @last_tick
      @tick_rate = (Settings.updaterate / delta2).to_i
    end
    
    @hooks.delete_if { |item|
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
    @hooks << [@total_time + delta, block]
  end
  
  def wipe! call_all = true
    @hooks.each { |item| item.last.call } if call_all
    @hooks.clear
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

class GLFrameWork
  def init_gl_window(width = Settings.winX, height = Settings.winY)
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

  def define_screen virtual_x = Settings.winX, virtual_y = Settings.winY
    GL::MatrixMode(GL::PROJECTION);
    GL::LoadIdentity();
    GL::Viewport(0,0,Settings.winX,Settings.winY);
    GL::Ortho(0,virtual_x,virtual_y,0,0,128); # TODO make this 1 : ration per default, not x : y
    GL::MatrixMode(GL::MODELVIEW);
  end

  attr_accessor :running, :timer, :fpstext
  
  def initialize
    @timer = Timer.new
    
    SDL.setVideoMode(Settings.winX, Settings.winY, 0, (SDL::FULLSCREEN * Settings.fullscreen)|SDL::OPENGL|SDL::HWSURFACE)
    
    init_gl_window(Settings.winX, Settings.winY)
    SDL::WM.setCaption(Settings.win_title, "")
    SDL::Mouse.hide()

    @fpstext = Text.new(10, 10, 20, Color.new(255, 100, 255, 1.0), Settings.fontfile, "FPS GO HERE")
    @fpstext.extend(TopLeftPositioning)
  end

  def window_title=(title)
    SDL::WM.setCaption(title, "")
  end
  
  def run!
    @running = true
    while @running do
      until (event = SDL::Event2.poll).nil?
        sdl_event(event)
        if not @running # FIXME something broken here!
#          throw "should no longer run"
Process.exit!(0) #FIXME ... but makes things work
        end
      end
      
      delta = @timer.tick

      @fpstext.tick delta
      @fpstext.set_text "rendering @#{$gfxengine.timer.ticks_per_second}fps"

      update_gfx delta # TODO call engine here (that may call gfx engine)
      draw_gl_scene # TODO call gfx engine here -- no methods from self.

      @fpstext.render if Settings.show_fps
      SDL.GLSwapBuffers
    end
  end
  
  def kill!
    @running = false
  end
end

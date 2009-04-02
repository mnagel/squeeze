#!/usr/bin/env ruby -wKU

=begin
    filler - a simple game.
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

    $Id$

=end

require 'args_parser'
switches = []
@helpswitch = Switch.new('h', 'print help message',	false, proc { puts "this is oneshot #{THEVERSION}"; switches.each { |e| puts '-' + e.char + "\t" + e.comm }; Process.exit })
switches = [
  Switch.new('g', 'select path with gfx (relative to gfx folder)', true, proc {|val| $GFX_PATH = val}),

  @helpswitch
]

fileswitch = proc { |val| puts "dont eat filenames, not even #{val}"};
noswitch = proc {|someswitch| log "there is no switch '#{someswitch}'\n\n", LOG_ERROR; @helpswitch.code.call; Process.exit };

helpswitch = @helpswitch

$GFX_PATH = ''
parse_args(switches, helpswitch, noswitch, fileswitch)

inf = $GFX_PATH
inf = '' if inf.nil?

GOODGFX = "gfx/filler/#{inf}/good/"
BADGFX  = "gfx/filler/#{inf}/bad/"
WINDOWTITLE = "glfiller.rb by Michael Nagel"

silently do require 'sdl' end
require 'opengl'
require 'glbase'
require 'filler'

require 'v_math'

def draw_gl_scene
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  define_screen 600, 600
  
  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

  $engine.objects.each do |x|
    x.render
  end

  $engine.scoretext.render
  $engine.m.render

  $engine.messages.each { |message| message.render }
end

class Circle < Square
  def initialize(x, y, size, text=nil)
    super x, y, size
    @texture = text
    @texture = $engine.m.gonna_spawn if @texture.nil?
    @r = $engine.m.r
    @colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end
end

$mousedef = 40 # TODO cleanup
class GFXEngine


  # TODO MOVE TO BACKEND!!!
  def update_gfx dt
    $engine.messages.each { |message| message.tick dt }
    $engine.m.tick dt


    $engine.scoretext.set_text("score: #{($engine.score * 100).to_i}, total: #{($engine.scoreges * 100).to_i}")
    $engine.scoretext.tick dt

    $engine.objects.each do |x|
      x.tick dt
    end
  end

 

  def prepare
    $engine.messages = []
    $engine.scoretext = Text.new(10, 30, 20, Color.new(255, 100, 255, 1.0), FONTFILE, "SCORE GO HERE")
    $engine.scoretext.extend(TopLeftPositioning)

    $tex = []
    good = GOODGFX
    Dir.entries(good).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{good}#{fn}"
      text = Texture.load_file(thef)
      $tex << text
    }

    $ene = []
    bad = BADGFX # "gfx/filler/bad/"
    Dir.entries(bad).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{bad}#{fn}"
      text = Texture.load_file(thef)
      $ene << text
    }

    $gfxengine.window_title = WINDOWTITLE
  end
end

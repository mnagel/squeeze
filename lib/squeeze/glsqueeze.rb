#!/usr/bin/env ruby -wKU

=begin
    squeeze - a simple game.
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
  
  if $engine.gamemode == GameMode::ENTER_NAME
    GameMode.enter_name_input.render
    GameMode.enter_name_headline.render
  end

    if $engine.gamemode == GameMode::SHOW_SCORES
    puts "GameMode.hs_text  is nil" if GameMode.show_highscores_texts.nil?
    

    GameMode.show_highscores_texts.each do |item| item.render end
  end

end

# TODO rename circle so that is is clear what it really is (square + texture)
class Circle < Square
  def initialize(x, y, size, text=nil)
    super x, y, size
    @texture = text
    @texture = $engine.m.gonna_spawn if @texture.nil?
    @r = $engine.m.r
    @colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end
end

class GLFrameWork
  def update_gfx dt
    $engine.update dt # TODO reverse logic here, let the engine call the gfx
    
    $engine.messages.each { |message| message.tick dt }
    $engine.m.tick dt

    $engine.scoretext.set_text("score: #{($engine.scoreges).ceil.to_i} -- level up: #{(($engine.level_up_score-$engine.score)).ceil.to_i}") # TODO 0.5 is evil hack
    $engine.scoretext.tick dt
  end

  def prepare
    $engine.messages = []
    #$engine.scoretext = Text.new(10, 30, 20, Color.new(255, 100, 255, 1.0), Settings.fontfile, "SCORE GO HERE")
    $engine.scoretext = Text.new(Settings.winX / 2, 30, 20, Color.new(255, 100, 255, 1.0), Settings.fontfile, "SCORE GO HERE")
    #$engine.scoretext.extend(TopLeftPositioning)

    $tex = []
    good = Settings.gfx_good
    Dir.entries(good).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{good}#{fn}"
      text = Texture.load_file(thef)
      $tex << text
    }

    $ene = []
    bad = Settings.gfx_bad
    Dir.entries(bad).reject { |e| not e =~ /.*\.png/}.each { |fn|
      thef = "#{bad}#{fn}"
      text = Texture.load_file(thef)
      $ene << text
    }
  end
end

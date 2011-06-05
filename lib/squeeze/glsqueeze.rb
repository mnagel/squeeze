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

=end

def draw_gl_scene
  GL::Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
  define_screen
  GL::Enable(GL::BLEND)
  GL::BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

  $back.render

  $engine.objects.each do |x|
    x.view.render
  end

  $engine.scoretext.render
  $engine.mouse.view.render

  $engine.messages.each { |message| message.render }

  if GameMode.get_mode != GameMode::NORMAL

      GameMode.fader.render
  end

  if GameMode.get_mode == GameMode::ENTER_NAME
    GameMode.enter_name_input.render
    GameMode.enter_name_headline.render
  end

  if GameMode.get_mode == GameMode::SHOW_SCORES
    puts "GameMode.hs_text  is nil" if GameMode.show_highscores_texts.nil?
    GameMode.show_highscores_texts.each do |item| item.render end
  end

end

# TODO rename circle so that is is clear what it really is (square + texture)
class Circle < Square
  def initialize(x, y, size, text=nil)
    super x, y, size
    @texture = text
    @texture = $engine.mouse.view.gonna_spawn if @texture.nil?
    @r = $engine.mouse.view.r
    @colors = ColorList.new(4) do Color.new(1.0, 1.0, 1.0, 1.0) end
  end
end

class GLFrameWork
  def update_gfx dt
    $engine.update dt # TODO reverse logic here, let the engine call the gfx
    
    $engine.messages.each { |message|
      message.tick dt
    }
    $engine.mouse.model.tick dt

    $engine.objects.each {|o|
      o.view.tick dt
    }

    $engine.scoretext.set_text("score: #{($engine.score_object.scoreges).ceil.to_i} -- level up: #{(($engine.score_object.level_up_score-$engine.score_object.score)).ceil.to_i}") # TODO 0.5 is evil hack
    $engine.scoretext.tick dt
  end

  def prepare
    $engine.messages = []
    $engine.scoretext = Text.new(Settings.winX / 2, 30, 20, Color.new(255, 100, 255, 1.0), Settings.fontfile, "SCORE GO HERE")

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

    $back2 = Texture.load_file(Settings.gfx_back)
    $back = Rect.new(0, 0, Settings.winX / 2, Settings.winY / 2)
    v = 0.3
    $back.colors = ColorList.new(4) { |i| Color.new(v, v, v, 1.0) }
    $back.extend TopLeftPositioning
    $back.texture = $back2
  end
end

  def create_highscore_texts
    hs = $hs.get(3)
    puts "panic... got a nil" if hs.nil?
    GameMode.show_highscores_texts = []

    3.times do |i| GameMode.show_highscores_texts << Text.new(Settings.winX/2, Settings.winY * ((i+2)/5.0),
        Settings.fontsize * (1/3.0), Color.new(0, 255, 0, 0.8), Settings.fontfile, "#{i+1}. #{hs[i].score.to_i} -- #{hs[i].name}")
    end
  end

#!/usr/bin/env ruby

=begin
    sharpmath - mathematical parser and algebraic calculations
    Copyright (C) 2006, 2008, 2009 by Michael Nagel

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

module Velocity
  def self.extend_object(o)
    super
    o.instance_eval do @v = V.new end # sneak in the v AUTOMATICALLY...
  end

  attr_accessor :v

  def tick dt
    begin
      super
    rescue => exc
      STDERR.puts "no super"
      STDERR.puts "i am a: #{self}"
      #1/0
    end

    begin

    @pos.x += @v.x * dt
    @pos.y += @v.y * dt

          rescue => exc
      STDERR.puts "no pos method"
      STDERR.puts "i am a: #{self}"
      #1/0
    end
  end
end

module Gravity
  def tick dt
    super

    delta = 3
    suckup = -0.5
    if @pos.y  > Settings.winY - @size.y - delta
      @v.y *= 0.3 if @v.y > suckup and @v.y < 0 # TODO have another way of letting things rest...
      return
    end

    @v.y += dt * 0.01 # axis is downwards # TODO check if this is indepent of screen size
  end
end

module Bounded
#  @@bounce = Settings.bounce

  def weaken
    @v.x *= Settings.bounce #@@bounce
    @v.y *= Settings.bounce #@@bounce

    if self.respond_to?(:on_collide, false)
      self.on_collide("crashed wall")
    end
  end

  def tick dt # TODO rewrite the "bounded" code
    super
    # TODO objects "hovering" the bottom freak out sometimes
    if @pos.x < @size.x
      @pos.x = @size.x
      @v.x = -@v.x
      weaken
    end

    if @pos.y < @size.y
      @pos.y = @size.y
      @v.y = -@v.y
      weaken
    end

    if @pos.x > Settings.winX - @size.x
      @pos.x = (Settings.winX - @size.x)
      @v.x = -@v.x
      weaken
    end

    if @pos.y > Settings.winY - @size.y
      @pos.y = (Settings.winY - @size.y)
      @v.y = -@v.y
      weaken
    end
  end
end

module DoNotIntersect
  # TODO read about colission detection and resolution
  # http://box2d.org/manual.html
  # http://dotnetjunkies.com/WebLog/chris.taylor/archive/2006/09/30/148798.aspx
  # http://www.cs.unc.edu/~geom/collide/
  # http://www.ziggyware.com/readarticle.php?article_id=52
  # http://www.realtimerendering.com/
  # http://forums.xna.com/forums/t/17303.aspx
  # http://www.eetsgame.com/PPCD/#_Toc44013734
  # http://www.cs.unc.edu/~geom/index.shtml
  # http://games.fourtwo.se/xna/2d_collision_response_xna/
  # http://en.wikipedia.org/wiki/Collision_detection
  # http://web.comlab.ox.ac.uk/people/Stephen.Cameron/distances/
  # http://chrishecker.com/Rigid_Body_Dynamics

#  @@bounce = Settings.bounce

  def tick dt
    old_pos = self.pos.clone
    super dt

    collider = $engine.get_collider_model(self)

    unless collider.nil?
#      if @model.nil?
#        STDERR.puts "my model is nil"
#        STDERR.puts "i am a #{self}"
#
#      end

      self.pos = old_pos # TODO having them not move at all is not correct, either -- prevent them from getting stuck to each other

      r1, r2 = Math::collide(self.pos, collider.pos, self.v, collider.v, self.size.x ** 2 , collider.size.x ** 2)

      self.v = r1 * Settings.bounce #@@bounce
      collider.v = r2 * Settings.bounce #@@bounce

      if self.respond_to?(:on_collide, false)
        self.on_collide(collider)
      end

      if collider.respond_to?(:on_collide, false)
        collider.on_collide(self)
      end
    end
  end
end

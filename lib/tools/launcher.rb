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

    $Id$

=end

$LOAD_PATH << './lib/' << './lib/tools/'
a = ARGV[0]
ARGV.shift

# TODO put these in a utility file
class Float
  def self.rand min, max
    return min + Kernel.rand(0) * (max - min)
  end
end

class Array
  def rand
    return self[Kernel.rand(self.length)]
  end
end

# TODO clean up...
if a == "filler"
  $LOAD_PATH << './lib/filler'
  require "filler"
elsif a == "tictactoe"
  $LOAD_PATH << './lib/tictactoe'
  require "gltictactoe"
else
  throw "unknown command... #{ARGV.join()}"
end

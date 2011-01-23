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

$LOAD_PATH << './lib/' << './lib/tools/'
require "logger"
a = ARGV[0]
ARGV.shift

#http://www.kmc.gr.jp/~ohai/rubysdl_doc.en.html#label-617
#Others
#Avoid pthread problem
#
#You can possibly avoid Ruby/SDL pthread problem when you put following in your script.

require 'rbconfig'

if RUBY_PLATFORM =~ /linux/
  trap('INT','EXIT')
  trap('EXIT','EXIT')
end



  # get a file as single string
  # TODO put this somewhere better
  # TODO can fail badly
  def get_file_as_string(filename)
    data = ''
    f = File.open(filename, "r")
    f.each_line do |line|
      data += line
    end
    return data
  end

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

def silently(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  result
end

# TODO clean up..., have hash with key and proc...
if a == "squeeze"
  $LOAD_PATH << './lib/squeeze'
  require "squeeze"
elsif a == "tictactoe"
  $LOAD_PATH << './lib/tictactoe'
  require "gltictactoe"
elsif a == "crush"
  $LOAD_PATH << './lib/crush'
  require "crush"
else
  throw "unknown command... #{ARGV.join()}"
end

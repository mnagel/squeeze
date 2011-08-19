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

require 'ruby-prof'
DEST = STDOUT

def silently(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  return result
end

def profiled(&block)
  RubyProf.start

  block.call

  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)

  silently do
    printer.print(DEST, 0)
    puts "profiling result has been written"
  end
end

profiled do # TODO update...
  puts Dir.pwd
  ARGV = ["squeeze"]
  require 'lib/tools/launcher'
end

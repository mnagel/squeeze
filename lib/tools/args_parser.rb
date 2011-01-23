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

# TODO port improved switching code back to oneshot
# TODO support reading from a file, too
# TODO include example...

class Switch
  attr_accessor :char, :comm, :args, :code

  def initialize char, comm, args, code
    @char = char
    @comm = comm
    @args = args
    @code = code
  end
end

def parse_args switches, helpswitch, noswitch, fileswitch

  puts "parsing #{ARGV.join(" ")}"

  notargs = []

  ARGV.each_index { |i|
    next if notargs.include?(i)

    arg = ARGV[i].dup

    if arg[0..0] == '-'
      arg[1..-1].scan(/./) do |chr|
        myswitch = switches.find {|s| s.char == chr}
        noswitch.call(chr) if myswitch.nil?
        if myswitch.args
          myswitch.code.call(ARGV[i+1])
          notargs << i+1
        else
          myswitch.code.call
        end
      end
    else
      fileswitch.call(ARGV[i])
    end
  }
end

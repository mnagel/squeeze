#!/usr/bin/env ruby -wKU

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

profiled do
  puts Dir.pwd
  require 'lib/gltictactoe'
end

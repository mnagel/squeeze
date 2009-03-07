#!/usr/bin/env ruby -wKU

def silently(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  result
end

def profiled(&block)
  require 'ruby-prof'
  RubyProf.start

  block.call

  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  dest = STDOUT
  silently do printer.print(dest, 0); puts "profiling result has been written" end
end

profiled do puts Dir.pwd; require 'lib/gltictactoe' end

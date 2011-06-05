#!/usr/bin/env ruby

# pre-insert startup scripts and docu
list = ["squeeze", "tictactoe", "index.htm"]

require 'find'
dirs = ["lib", "gfx", "sfx", "website"]
excludes = ["alt", "crush", "downloads"]
for dir in dirs
  Find.find(dir) do |path|
    if FileTest.directory?(path)
      if excludes.include?(File.basename(path))
        Find.prune       # Don't look any further into this directory.
      else
        next
      end
    else
      list << path
    end
  end
end

args = "glgames.version-XXX.tar #{list.join(" ")}"
puts args

system("tar -cvvf #{args}")

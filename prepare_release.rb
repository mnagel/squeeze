#!/usr/bin/env ruby

list = []

require 'find'
dirs = ["lib", "gfx"]
excludes = [".svn", "alt"]
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

args = "glgames.XXX.tar #{list.join(" ")}"
puts args

system("tar -cvvf #{args}")

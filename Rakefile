#!/usr/bin/env ruby -rubygems

=begin
    tictactoe - tic tac toe game
    Copyright (C) 2008, 2009 by Michael Nagel

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

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

# task to be done when building the project...
task :default => [:test]

# the rdoc task(s) (family)
Rake::RDocTask.new do |rd|
  rd.name = :rdoc
  rd.rdoc_dir = "rdoc"
  rd.main = "lib/glbase.rb"
  rd.title = "documentation for glbase"
  rd.rdoc_files.include("lib/**/*.rb")
  rd.options << "--line-numbers" << "--inline-source" << "--diagram" << "--fileboxes" << "--all"
end

# the test task(s)
Rake::TestTask.new do |t|
  t.libs << "test"
  # tests to run
  t.test_files = FileList['test/testsuite.rb'] 
  t.verbose = true
end

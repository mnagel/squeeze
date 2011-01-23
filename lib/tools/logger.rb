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

# TODO create module, and move out only the "log" method
# TODO set default log levels... error, warn, ...

DEFAULT_FILE = "run.log"
# how timestamps should be formatted
DATEFORMAT = "%Y-%m-%d %H:%M:%S"
# how levels are indented in text-based loggers
LEVELPREFIX = " . "
# all the loggers
# some are added at the end of this file (dont exist yet :)
# some will be added at runtime, probably (i.e. the ingame treeview with logs...)
LOGGERS = []
# current indentation levl
@@indentation_level = 0

def create_default_loggers
  LOGGERS.push($clogger = ConsoleLogger.new, $flogger = FileLogger.new(DEFAULT_FILE))
end

# base class of all loggers
class LoggerClass
  attr_accessor :thresholds 
  
  def initialize
    @thresholds = {
      'glbase'    => 0,
      'v_math'    => 0
    }
  end
  
  def load_ts fn
    @thresholds = load_hash(fn){return @thresholds}
  end
  
  def save_ts fn
        #fn = ENV['HOME'] + '/.sharpmath/formulae.marshal.gzip'
    save_hash(@thresholds, fn){log "saving failed", 0, :error}
  end
  
  def should_show component, messagelevel
    cutoff = @thresholds[component]
    if cutoff.nil?
      cutoff = 0 
      @thresholds[component] = -42
    end
    
    return messagelevel >= cutoff
  end
  
  # TODO make more widespread use
  # if changing indent. plus = +1
  def change_indent plus
    # nothing here
  end
end

def get_indent
  return LEVELPREFIX * @@indentation_level
end



# a logger outputting plain text to standard output
class ConsoleLogger < LoggerClass
  def log_raw string, component, timestring
    puts sprintf("%s - %s - %s", timestring, component, get_indent + string)
  end
end

class HTMLLogger < LoggerClass
  def log_raw string, component, timestring
    # TODO inherit the pre...?!
    puts sprintf("<li class=\"pre\">%s - %s - %s</li>", timestring, component, string)
  end
  
    # if changing indent. plus = +1
  def change_indent plus
    super(plus)
    puts plus ? "<li><ul class=\"pre\">" : "<li class =\"none\">LAST</li> </ul></li>"
  end
end



# a logger outputting plain text to a file (append mode)
class FileLogger < LoggerClass
  def initialize filename
    super()
    @file = filename
    @filename_printed = false
  end
  
  def log_raw string, component, timestring
    File.open(@file, 'a') { |f|
      unless @filename_printed
        @filename_printed = true
        # force_wd
        log("file logger is going to write to: #{Dir.getwd + '/' + @file}", 0, :logger)
      end
      f.puts sprintf("%s - %s - %s", timestring, component, get_indent + string)
    }
  end
end



# a logger displaying messages in a gtk treeview
class GTKTreeLogger < LoggerClass
  def initialize treeviewwidget
    super()
    @tvw = treeviewwidget
    # mark clicked cells
    @tvw.signal_connect("cursor_changed") {|instance|
      sel = @tvw.selection.selected  
      sel[3] = true unless sel.nil?
    }
    # message, component, timestamp, marked?
    @tvw.model = @treestore = Gtk::TreeStore.new(String, String, String, Object)
    
    renderer = Gtk::CellRendererText.new
    
    col = Gtk::TreeViewColumn.new("Message", renderer, :text => 0)
    col.set_cell_data_func(renderer) {|col, renderer, model, iter|
      # color marked cells in red
      renderer.background = iter[3] ? "red" : nil;
    }
    col.resizable = true
    @tvw.append_column(col)
    
    col = Gtk::TreeViewColumn.new("Component", renderer, :text => 1)
    col.resizable = true
    @tvw.append_column(col)
    
    col = Gtk::TreeViewColumn.new("Timestamp", renderer, :text => 2)
    col.resizable = true
    @tvw.append_column(col)
    
    # for easier maintaining of indentation
    @parents = []
  end
  
  # TODO force redraws
  def log_raw string, component, timestring
    # unindent if necessary
    @parents.pop while (@@indentation_level < @parents.length and @@indentation_level >= 0)
    # ident if necessary
    @parents.push @last if @@indentation_level > @parents.length
    
    item = @treestore.append(@parents.last)
    
    item[0] = string
    item[1] = component.to_s
    item[2] = timestring
    item[3] = false # mark as not marked
    
    # TODO seems to not scroll to the right place
    @tvw.scroll_to_cell(item.path, nil, true, 1.0, 0.0)
    @tvw.expand_all
    
    @last = item
  end  
end

# global function writing log messages to all loggers
# string: message to write out
# importance: (optional) importance of message
# component: (optional) component message is coming from
def log string, importance = 0, component = nil
  time_string = "(" + Time.now.strftime(DATEFORMAT) + ")"
  
  LOGGERS.each { |logger| 
    logger.log_raw(string.to_s, component.to_s, time_string) if logger.should_show(component, importance)
  }
end

# enter a block in logging
def logbegin string, loglevel = 0, component = nil
  log string, loglevel, component
  @@indentation_level += 1
  LOGGERS.each {|logger|
    logger.change_indent(true)
  }
end

# leave block in logging
def logend
  @@indentation_level -= 1
  
  LOGGERS.each {|logger|
    logger.change_indent(false)
  }
end

# create default loggers
create_default_loggers

=begin
    squeeze - a simple game.
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

class Settings__ < SettingsBase
  attr_accessor :bounce, :show_bounding_boxes, :mousedef, :infotext
  attr_accessor :gfx_good, :gfx_bad, :gfx_back, :fontsize

  PROGNAME = "squeeze"

  def initialize
    super

    @show_fps = false
    @winX = 1680 #500 # TODO constants for these defaults
    @winY = 1050 #500
    @fullscreen = 1

    # TODO clean up the new settings code..., remove onshot references
    switches = []
    @helpswitch = Switch.new('h', 'print help message',	false,
      proc {
        puts "this is oneshot"
        switches.each { |e|
          puts '-' + e.char + "\t" + e.comm
        };
        Process.exit
      })
    switches = [
      Switch.new('g', 'select path with gfx (relative to gfx folder)', true, proc {|val| $GFX_PATH = val}),
      Switch.new('s', 'select path with sfx (relative to sfx folder)', true, proc {|val| $SFX_PATH = val}),
      Switch.new('f', 'enable fullscreen mode (1/0)', true, proc {|val| @fullscreen = val.to_i}),
      Switch.new('x', 'set x resolution', true, proc {|val| @winX = val.to_i}),
      Switch.new('y', 'set y resolution', true, proc {|val| @winY = val.to_i}),
      @helpswitch
    ]

    fileswitch = proc { |val| puts "dont eat filenames, not even #{val}"};
    # TODO dont use puts below!
    noswitch = proc {|someswitch|
      puts("there is no switch '#{someswitch}'\n\n", 0, nil);
      @helpswitch.code.call;
      Process.exit
    };

    helpswitch = @helpswitch

    # TODO dont use global var

    # TODO dont use global var
    $SFX_PATH = 'default'

    inf2 = $SFX_PATH
    inf2 = 'default' if inf2.nil?


    $GFX_PATH = 'default'
    parse_args(switches, helpswitch, noswitch, fileswitch)

    inf = $GFX_PATH
    inf = 'default' if inf.nil?



    @fontsize = 150 * @winX / 750.0  # TODO check scaling
    @gfx_good = "gfx/#{PROGNAME}/#{inf}/good/"
    @gfx_bad = "gfx/#{PROGNAME}/#{inf}/bad/"
    @gfx_back = "gfx/#{PROGNAME}/#{inf}/back.png"
    @win_title = "#{PROGNAME} by Michael Nagel"
    @bounce = 0.8
    @show_bounding_boxes = false
    @mousedef = 40 * @winX / 750.0 # 40 # TODO introduce vars for 750 and 40
    @infotext  = <<EOT
    #{PROGNAME} - a simple game.
    Copyright (C) 2009 by Michael Nagel
EOT
  end
end

Settings = Settings__.new

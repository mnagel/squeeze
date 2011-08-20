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

# TODO make independent from squeeze

# TODO sanatize to ints only, make level-up callback, add level management here...
class Score
  attr_accessor :score, :scoreges, :cur_level, :level_up_score

  def initialize
    @scoreges, @score = 0, 0
  end

  def level_up
    @score = 0
  end

  def score_points points
    @score += points
    @scoreges += points
  end

  def to_highscore name
    res = HighScore.new(name, @scoreges)
    res.date = Time.now.strftime(DATEFORMAT)
    res.comment = "comment: score = #{@score}; level = #{@cur_level}"
    return res
  end
end

# a simple record of a highscore
class HighScore
  attr_accessor :name, :score, :date, :comment

  def initialize name, score
    @name, @score = name, score
  end
end

# list of highscore records building the highscore list
class HighScores
  # individual highscore entries
  attr_accessor :entries

  # create new list
  def initialize
    @entries = []
    puts "init of highscores..."
  end

  # get top n entries in order
  def get n
    # TODO order by date as second criterium
    @entries.sort! { |a,b| a.score <=> b.score }.reverse!
    return @entries.slice(0..n-1)
  end

  def is_in_best val, n
    ref = (get n).last.score
    return val > ref
  end

  # enter an entry to the table
  def add name, score_object
    @entries << score_object.to_highscore(name)
  end

  # load table from file
  def self.load path
    if File.exist? path
      puts "reading highscore from #{path}"
      return YAML::load(get_file_as_string(path))
    else
      puts "creating new highscore"
      a = HighScores.new
      puts "hs in method is #{a.to_s}"
      [99, 499, 999].each do |i| # TODO add variables
        s = Score.new
        s.score_points(i)
        s.cur_level = -1
        a.add "nobody", s
      end
      puts "hs in method is #{a.to_s}"
      return a
    end
  end

  # keep only the top n entries
  def truncate n
    limit = get(n).last.score
    @entries.reject! { |item| item.score < limit }
  end

  # save table to file
  def save path
    truncate 5
    serialized = self.to_yaml

    file = File.new(path, "w")
    file.write(serialized)
    file.close
  end
end

# TODO put this somewhere else and delay till startup...
# TODO dispose of global var
HIGHSCOREFILEPATH = "#{ENV['HOME']}/.squeeze.hs.yaml"
$hs =  HighScores.load HIGHSCOREFILEPATH

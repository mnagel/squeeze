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

=end

# the Matrix class is used to store two dimensional data
class Matrix
  # x, y:: the size of the matrix
  # yield:: block to populate the matrix
  def initialize x, y
    @x, @y = x,y
    @val = Array.new(x) { |i| Array.new(y) { |j| yield(i,j)  } }
  end

  # allows acessing the values directly
  def [](index)
    @val[index]
  end

  # yield:: block is called for each value, with indexes and value
  def each
    @val.each_with_index { |o, i|
      o.each_with_index { |p, j| yield(i,j,p) }
    }
  end

  # returns a deep copy of the matrix
  def clone
    return (Matrix.new(@x,@y) do |i,j| self[i][j].clone end)
  end
end

# the Mark class represents the nine marks on the board
class Mark
  attr_reader :x, :y, :winner
  attr_accessor :player

  def initialize x, y
    @x, @y = x, y
    @player, @winner = 0, false
  end

  def is_winner!
    @winner = true
  end

  def to_s
    "|#{@x}-#{@y}--#{@player}|"
  end
end

# class to simulate a game of tictactoe
class TicTacToe

  # mapping between the num-pad - keys and the coordinates in the game field
  $keymap = Hash.new
  (0..8).each { |i| $keymap[i+1] = [i%3,(8-i)/3] }

  # internal array used to represent the state of the game
  # readable to allow unit-testing and the like
  attr_accessor :field, :player

  # constructor
  # creating a new @field
  # setting @player to 2, because it's flipped before a move
  def initialize
    @field = Matrix.new(3,3){|i,j| Mark.new(i,j) }
    @player = 1
    on_game_start
  end

  # prints the field, with the board on the left and a list of possible moves
  # on the right
  # adds some kind of boarder around...
  def to_s
    r = "##### ##### ##### ##### #####\n"
    (0..2).each { |y|
      (0..2).each { |x|
        r += get_print_char(x,y, '.') + " "
      }
      r += (" " * 5)
      (0..2).each { |x|
        r += get_print_char(x,y, nil, " ", " ") + " "
      }
      r += "\n"
    }
    r += '##### ##### ##### ##### #####'
  end

  # find the character that will be used to print...
  # *index*:: index des zu besetzenden feldes
  # *leer*:: character for empty fields
  # *one*:: character for fields occupied by player one
  # *two*:: same for player two
  def get_print_char x,y, leer = nil, one = 'X', two = 'O'

    #return "@" if @field[x][y].winner

    case @field[x][y].player
    when 1 then one
    when 2 then two
    else
      if leer.nil? then
        $keymap.invert[[x,y]].to_s
      else
        leer
      end
    end
  end

  def on_game_start

  end

  def on_gameover

  end

  def on_game_won winner, winning_stones
    puts "#{winner} won the game"

    winning_stones.each do |item|
      item.is_winner!
    end
  end

  # switch players, get a valid move and update the field according to the move
  def do_move x,y
    return unless is_valid_move(x,y)
    @field[x][y].player = @player
    unless (w = check_winner).nil?
      on_game_won  w.first.player, w
    end

    @player = @player == 1 ? 2 : 1
    if gameover?
      @player = 0
      on_gameover
    end
  end

  # check if a move is valid, i.e. 1-9 on a unoccupied field, or 0 for ai move
  def is_valid_move x,y
    return false unless (0..3) === x
    return false unless (0..3) === y
    return @field[x][y].player == 0
  end

  # get a move (from user) that is definitely valid
  def get_valid_move
    begin
      puts 'please enter your move: '
      i = gets.chomp.to_i
      if i == 0
        return ki_get_move
      else
        x,y = $keymap[i]
      end
    end until is_valid_move(x,y)
    return x,y
  end

  def check_winner thefield = @field
    winners = []

    checks = []

    d1 = []
    d2 = []
    (0..2).each { |a|
      c1 = []
      c2 = []
      (0..2).each { |b|
        c1 << thefield[a][b]
        c2 << thefield[b][a]
      }
      checks << c1
      checks << c2

      d1 << thefield[a][a]
      d2 << thefield[a][2-a]
    }
    checks << d1
    checks << d2

    (1..2).each { |player|
      checks.each { |c|
        d = c.map { |item| item.player } << player
        if (d.uniq.length == 1 and (1..2) === d.first)
          c.each { |var| winners << var }
        end
      }
    }
    if winners.length > 0
      return winners
    end

    return nil
  end

  # returns true if the field is full
  def full?
    for x in 0..2
      for y in 0..2
        return false if @field[x][y].player == 0
      end
    end
    return true
  end

  # returns true if either the field is full or one player won the game
  def gameover?
    full? or not check_winner.nil?
  end

  # ask the ai for a move
  # the ai does:
  # * choose a random field that is not occupied
  # * if its a winning field accept it
  # * if its a winning field for the other player probably accept it
  # * otherwise accept it perhaps
  # * if the field was not accepted, choose again
  def ki_get_move
    field2 = @field.clone
    srand

    while true
      tryx, tryy = rand(3), rand(3)
      next unless field2[tryx][tryy].player == 0

      field2[tryx][tryy].player = @player
      if check_winner(field2) != nil and check_winner(field2).first.player == @player then
        return tryx, tryy
      end

      other = @player == 1 ? 2 : 1
      field2[tryx][tryy].player = other
      if check_winner(field2) != nil and check_winner(field2).first.player == other then
        if rand(10) > 1 then
          return tryx, tryy
        end
      end

      field2[tryx][tryy].player = 0
      if rand(10) > 8 then return tryx,tryy end
    end
  end
end

# when run as executable, start a game and run it...
if __FILE__ == $0
  begin
    game = TicTacToe.new

    puts game.to_s
    puts "possible moves listed on the right, 0 lets AI pick a move"

    while !(game.gameover?)
      a,b = game.get_valid_move
      game.do_move(a,b)
      puts game.to_s
    end

    if (temp = game.check_winner).nil?
      puts 'game over'
    else
      puts 'player ' + temp.first.player.to_s + ' won the game!'
    end
  end while begin
    puts "again? 1/0 goes again, everything else stops: "
    ["1", "0"].include?(gets.chomp!)
  end
end

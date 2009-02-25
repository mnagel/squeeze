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

$keymap = Hash.new
(0..8).each { |i| $keymap[i+1] = [i%3,(8-i)/3] }

class Array2D
  def initialize x, y
    @val = Array.new(x) { |i| Array.new(y) { |j| 0 } }
  end
  
  def [](index)
    @val[index]
  end
  
  def each
    @val.each_with_index { |o, i| 
      o.each_with_index { |p, j| yield(i,j,p) }
    }
  end
end

# class to simulate a game of tictactoe
class TicTacToe
	
  # internal array used to represent the state of the game
  # readable to allow unit-testing and the like
  attr :field
	
  # constructor
  # creating a new @field 
  # setting @player to 2, because it's flipped before a move
  def initialize
    @field = Array2D.new(3,3)
    @player = 2
  end
  
  # prints the field, with the board on the left and a list of possible moves
  # on the right
  # adds some kind of boarder around...
  def to_s
    r = "##### ##### ##### ##### #####\n"
    (0..2).each { |y|
      (0..2).each { |x| 
        r += getPrintChar(x,y, '.') + " "
      }
      r += (" " * 5)
      (0..2).each { |x| 
        r += getPrintChar(x,y, nil, " ", " ") + " "
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
  def getPrintChar x,y, leer = nil, one = 'X', two = 'O'
    case @field[x][y]
    when 1 then one
    when 2 then two
    else
      if leer.nil? then 
        $keymap.invert[[x,y]].to_s #$keymapI[3*x+y].to_s
      else
        leer
      end
    end
  end

  # switch players, get a valid move and update the field according to the move
  def doMove x,y
    @player = @player == 1 ? 2 : 1
    @field[x][y] = @player
  end

  # check if a move is valid, i.e. 1-9 on a unoccupied field, or 0 for ai move
  def isValidMove x,y
    return false unless (0..3) === x
    return false unless (0..3) === y
    return @field[x][y] == 0
  end	

  # get a move (from user) that is definitely valid
  def getValidMove
    begin
      puts 'please enter your move: '
      i = gets.chomp.to_i
      if i == 0
        return kiGetMove
      else
        x,y = $keymap[i]			
      end
    end until isValidMove(x,y)
    return x,y
  end
	
  # check if there is a winner
  # * returns nil for no winner
  # * returns 1 if player 1 wins
  # * returns 2 if player 2 wins
  # if both players won, 1 is returned
  def checkWinner thefield = @field
    # beide spieler
    for i in 1..2 do
      # waagerecht
      for d in 0..2 do
        b = [i]
        for t in 0..2 do
          b << thefield[d][t]
        end
        return i if b.uniq.length == 1
      end
      for d in 0..2 do
        b = [i]
        for t in 0..2 do
          b << thefield[t][d]
        end
        return i if b.uniq.length == 1
      end
      # diagonal
      return i if [i, thefield[0][0], thefield[1][1], thefield[2][2]].uniq.length == 1
      return i if [i, thefield[0][2], thefield[1][1], thefield[2][0]].uniq.length == 1
    end
    
    return nil
  end
  
  # returns true if the field is full
  def voll? 
#    return false
#    @field.all? { |x|  # TODO check if this works
#      x != 0
#    }
  for x in 0..2
    for y in 0..2
      return false if @field[x][y] == 0
    end
  end
  return true
  end

  # returns true if either the field is full or one player won the game
  def gameover?
    voll? or not checkWinner.nil?
  end

  # ask the ai for a move
  # the ai does:
  # * choose a random field that is not occupied
  # * if its a winning field accept it
  # * if its a winning field for the other player probably accept it
  # * otherwise accept it perhaps
  # * if the field was not accepted, choose again
  def kiGetMove
    field2 = @field.clone
    srand

    while true
      tryx, tryy = rand(3), rand(3)
      next unless @field[tryx][tryy] == 0

      field2[tryx][tryy] = @player
      if checkWinner(field2) == @player then return tryx,tryy end

      other = @player == 1 ? 2 : 1
      field2[tryx][tryy] = other
      if checkWinner(field2) == other then if rand(10) > 1 then return tryx,tryy end end

      field2[tryx][tryy] = 0
      if rand(10) > 8 then return tryx,tryy end
    end
  end
end

# when run as executable, start a game and run it...
if __FILE__ == $0
  begin
    myGame = TicTacToe.new

    puts myGame.to_s
    puts "possible moves listed on the right, 0 lets AI pick a move"

    while !(myGame.gameover?)
      a,b = myGame.getValidMove
      myGame.doMove(a,b)
      puts myGame.to_s
    end 

    if (temp = myGame.checkWinner).nil?
      puts 'game over'
    else
      puts 'player ' + temp.to_s + ' won the game!'
    end
  end while begin
    puts "again? 1/0 goes again, everything else stops: "
    ["1", "0"].include?(gets.chomp!)
  end
end
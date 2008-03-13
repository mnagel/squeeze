# keymap
# *key*:: key on numpad
# *value*:: index in internal array
$keymap = {
	1 => 6,
	2 => 7,
	3 => 8,
	4 => 3,
	5 => 4,
	6 => 5,
	7 => 0,
	8 => 1,
	9 => 2
}

# inverted keymap
# *key*:: index in internal array
# *value*:: key on numpad
$keymapI = $keymap.invert

# class to simulate a game of tictactoe
class TicTacToe
	
	# internal array used to represent the state of the game
	# readable to allow unit-testing and the like
	attr :field
	
	# constructor
  # creating a new @field 
  # setting @player to 2, because it's flipped before a move
	def initialize
			@field  = Array.new(9, 0)
			@player = 2
  end
	
	# prints the field, with the board on the left and a list of possible moves
	# on the right
	# adds some kind of boarder around...
	def to_s
		r = "##### ##### ##### ##### #####\n"
		[2,5,8].each { |index|  
			r += getPrintChar(index-2, '.') + " " +
					 getPrintChar(index-1, '.') + " " +
					 getPrintChar(index-0, '.') + " " +
					 (" " * 5) +
					 getPrintChar(index-2, nil, ' ', ' ') + " " +
					 getPrintChar(index-1, nil, ' ', ' ') + " " +
					 getPrintChar(index-0, nil, ' ', ' ') + "\n"
		} 
		r += '##### ##### ##### ##### #####'
	end
	
# find the character that will be used to print...
# *index*:: index des zu besetzenden feldes
# *leer*:: character for empty fields
# *one*:: character for fields occupied by player one
# *two*:: same for player two
	def getPrintChar index, leer = nil, one = 'X', two = 'O'
		case @field[index]
				when 1 then one
				when 2 then two
				else
					if leer.nil? then 
						$keymapI[index].to_s
					else
						leer
					end
		end
	end

	# switch players, get a valid move and update the field according to the move
	def doMove
		@player = @player == 1 ? 2 : 1
		move = getValidMove
		@field[move] = @player
  end

	# check if a move is valid, i.e. 1-9 on a unoccupied field, or 0 for ai move
	def isValidMove move
		return false unless (0..8) === move
		return @field[move] == 0
	end	

	# get a move (from user) that is definitely valid
	def getValidMove
		begin
				puts 'please enter your move: '
				i = gets.chomp.to_i
				if i == 0
					move = kiGetMove
				else
					move = $keymap[i]			
				end
		end until isValidMove move
		return move
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
				return i if [i, thefield[d+0], thefield[d+3], thefield[d+6]].uniq.length == 1
			end
			# senkrecht
			[0,3,6].each { |d| 
				return i if [i, thefield[d+0], thefield[d+1], thefield[d+2]].uniq.length == 1
			}
			# diagonal
			return i if [i, thefield[1-1], thefield[5-1], thefield[9-1]].uniq.length == 1
			return i if [i, thefield[7-1], thefield[5-1], thefield[3-1]].uniq.length == 1
		end

		return nil
	end

	# returns true if the field is full
	def voll? 
		@field.all? { |x| 
			x != 0
		}
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
			try = rand(9)
			next unless @field[try] == 0

			field2[try] = @player
			if checkWinner(field2) == @player then return try end

			other = @player == 1 ? 2 : 1
			field2[try] = other
			if checkWinner(field2) == other then if rand(10) > 1 then return try end end

			field2[try] = 0
			if rand(10) > 8 then return try end
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
			myGame.doMove
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
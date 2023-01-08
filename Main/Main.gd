#	TSA 2023 Video Game Design Project: Flip or Skip
#	
#	||---------------------------------------------------------------||
#	
#	Current Known Issues (commented where location of issue is known):
#		none! (for now)
#	
#	||---------------------------------------------------------------||

extends Node

export(PackedScene) var pawn_scene # used to create a new pawn child node when reviving

signal buttonsFinished(choice) # used to wait for input and action from multiple different button possibilities

var moving # is true while the player is in the middle of a move

# tracking pawns
var currentPawn # valid pawn that has been clicked to move (used to deal with invalid pawns clicked)
var oppositePawn # after a move, set to the pawn opposite of the current one

# tracking rolling and movement options
var rolled = false # is false and only true after a roll has occurred, after a move, it goes back to false
var roll # integer storing the roll number
var validTiles = ["", ""] # valid tiles that can be moved to based on the roll and currentPawn

# tracking rounds
var gameRound = 1 # the current game round
var cycles = 0 # the amount of full turn rotations gone, used to increment gameRound when all players have moved

# tracking tiles and pawns for specific uses
var tileCount = 28 # the total amount of tiles in play
var colorCount = 0 # the amount of pawns left in a certain color

# used for finding the next current player and managing which players are still in the game
var colors = ColorsSingleton.colors # current characters in play, using a global singleton to access it between scenes to modify amount of players when starting
var currentIndex = 0 # index used to increment the current player
var currentPlayer = colors[currentIndex] # current player color that can move

var stopAudio = false

onready var tween = get_node("Tween")

func _ready(): # ryns when the main scene is initialized into the scene tree
	randomize() # makes sure all numbers are random
	# hides correct tiles and buttons
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (int(tile.name.get_slice("-", 0)) != 1):
			tile.hide()
	$FlipButton.hide()
	$ReviveButton.hide()
	$SkipButton.hide()
	$PlayAgain.hide()
	$MainMenu.hide()
	$RollDisplay.playing = false
	$FlipDisplay.playing = false
	$BGMusic.play()
	
	for pawn in get_tree().get_nodes_in_group("all_pawns"):
		if (colors.find(pawn.color) == -1):
			pawn.queue_free()
	yield(get_tree(), "idle_frame")

func _process(_delta): # runs every frame
	$TurnDisplay.texture = load("res://Assets/" + currentPlayer + "-Turn.png")
	$RollButton.color = currentPlayer
	$FlipButton.color = currentPlayer
	$ReviveButton.color = currentPlayer
	$SkipButton.color = currentPlayer
	$PlayAgain.color = currentPlayer
	$MainMenu.color = currentPlayer
	
	var musicPosition = $BGMusic.get_playback_position()
	if ((musicPosition > 15.9 || (musicPosition > 7.99 && musicPosition < 8.02)) && stopAudio):
		$BGMusic.stop()

func _on_RollButton_pressed(): # runs when the roll button is pressed
	if (!rolled):
		if (gameRound != 4): # to make sure that rolls are adjusted for the smaller board
			roll = randi() % 6 + 1
		else:
			roll = randi() % 3 + 1
		
		$RollButton.hide() # hiding roll button until turn ends
		
		$RollDisplay.playing = true
		yield(get_tree().create_timer(2), "timeout")
		$RollDisplay.playing = false
		$RollDisplay.frame = roll - 1
		rolled = true # shows that the roll is done

func _on_Pawn_clicked(clickedPawn): # runs when the pawn is clicked
	if (get_node(clickedPawn).color == currentPlayer): # if the pawn is the correct color
		moving = true # starting the move
		currentPawn = clickedPawn # setting the clickedPawn only if it is the correct color
		
		for tile in get_tree().get_nodes_in_group("all_tiles"):
			tile.get_node("AnimatedSprite").frame = 0
		
		for pawn in get_tree().get_nodes_in_group("all_pawns"):
			pawn.get_node("AnimatedSprite").playing = false
			pawn.get_node("AnimatedSprite").frame = 0
		
		if (rolled):
			get_node(clickedPawn).get_node("AnimatedSprite").playing = true
		
		if (rolled): # if the player has rolled
			var checkTile = tileCheck(clickedPawn) # tile that the pawn is on
			
			# calculating the possible movement option tiles
			# note for later: when showing the valid tile sprites, make sure they show corresponding to the selected pawn and only if the tile is not covered by another pawn of the same color
			# (basically, only change the sprite of tiles that can actually be moved to for the selected pawn)
			var tileNum
			var backNum
			var forNum
			
			tileNum = int(checkTile.name.get_slice("-", 1))
			if (tileNum - roll < 1):
				backNum = tileCount + (tileNum - roll)
			else:
				backNum = tileNum - roll
			if (tileNum + roll > tileCount):
				forNum = (tileNum + roll) - tileCount
			else:
				forNum = tileNum + roll
			
			var option1 = str(gameRound) + "-" + str(backNum)
			var option2 = str(gameRound) + "-" + str(forNum)
			
			validTiles = [option1, option2]
			for tile in validTiles:
				var tilePawn = pawnCheck(tile) # pawn that is on the tile
				
				if (tilePawn == null || tilePawn.color != currentPlayer):
					get_node(tile).get_node("AnimatedSprite").frame = 1

func _on_Tile_clicked(clickedTile): # runs when a tile is clicked
	if (rolled && moving && (get_node(clickedTile).name in validTiles)): # if you have rolled, selected a tile, and the clickedTile is a valid movement option
		var tilePawn = pawnCheck(clickedTile) # pawn that is on the tile
		var moved = false # the move hasn't ended yet, so it is set to false
		
		for pawn in get_tree().get_nodes_in_group("all_pawns"):
			pawn.get_node("AnimatedSprite").playing = false
			pawn.get_node("AnimatedSprite").frame = 0
		
		if (tilePawn == null): # if there isnt a pawn on the tile
			tween.interpolate_property(get_node(currentPawn), "position", get_node(currentPawn).position, get_node(clickedTile).position, 0.3, 0, 2, 0)
			tween.start()
			
			moving = false # no longer in a move, so set to false
			
			moved = true # move is over, so set to true
		elif (get_node(currentPawn).color != tilePawn.color): # there is a pawn on the tile that is being moved too
			# swapping the piece positions
			var temp_pos = tilePawn.position
			tween.interpolate_property(tilePawn, "position", tilePawn.position, get_node(currentPawn).position, 0.3, 0, 2, 0)
			tween.interpolate_property(get_node(currentPawn), "position", get_node(currentPawn).position, temp_pos, 0.3, 0, 2, 0)
			tween.start()
			
			moved = true # move is over, so set to true
		
		if (moved): # if the move is over
			rolled = false # the roll has not been set for the next move
			
			for tile in get_tree().get_nodes_in_group("all_tiles"):
				tile.get_node("AnimatedSprite").frame = 0
			
			var oppositeTile = get_node(get_node(clickedTile).opposite_tile) # getting the opposite tile of the just finished move
			oppositePawn = pawnCheck(oppositeTile.name) # taking the opposite pawn as well
			
			if (oppositePawn != null): # if the opposite pawn exists
				get_node(clickedTile).get_node("AnimatedSprite").frame = 1
				oppositeTile.get_node("AnimatedSprite").frame = 1
				
				if (oppositePawn.color != get_node(currentPawn).color): # if the opposite pawn is a different color
					# show buttons for flip to kill
					$FlipButton.show()
					$SkipButton.show()
					yield(self, "buttonsFinished") # wait for the buttons function to finish
				else: # the opposite pawn is the same color
					yield(revive(), "completed") # calling the revive function, this makes sure that the player should be allowed to revive
			updateColors() # updates which players still remain because pawns may have been killed
			
			# turn over
			
			for tile in get_tree().get_nodes_in_group("all_tiles"):
				tile.get_node("AnimatedSprite").frame = 0
			
			$RollButton.show() # giving option to roll after turn ends
			
			# finding the last player alive
			var lastPlayer = "none"
			for color in colors:
				if (color != "dead"):
					lastPlayer = color
			
			# updating the cycles if the last player has moved
			if (currentIndex >= colors.find(lastPlayer)):
				cycles += 1
			
			# if the round is over
			if (cycles >= 3):
				$RollButton.hide()
				yield(get_tree().create_timer(1), "timeout") # just to see what's happening easier
				
				# updating values
				cycles = 0
				tileCount -= 8
				gameRound += 1
				
				if (gameRound > 4): # if there are no more rounds left, it should be a draw
					call_deferred("gameOver", "roundsOver")
				
				# killing pawns that are on unsafe squares
				var tiles = get_tree().get_nodes_in_group("all_tiles")
				for tile in tiles:
					var unsafePawn = pawnCheck(tile.name)
					
					if (unsafePawn != null && !tile.safe && int(tile.name.get_slice("-", 0)) == (gameRound - 1)):
						unsafePawn.get_node("AnimatedSprite").animation = unsafePawn.color + "-Dead"
						unsafePawn.get_node("AnimatedSprite").playing = true
						yield(get_tree().create_timer(1), "timeout")
						unsafePawn.get_node("AnimatedSprite").playing = false
						unsafePawn.get_node("AnimatedSprite").animation = unsafePawn.color
						
						unsafePawn.queue_free()
						yield(get_tree(), "idle_frame")
				updateColors() # updates which players still remain because pawns may have been killed
				
				yield(get_tree().create_timer(1), "timeout") # just to see what's happening easier
				# showing the next round's tiles
				for tile in tiles:
					if (int(tile.name.get_slice("-", 0)) == gameRound):
						tile.show()
					else:
						tile.hide()
				
				# moving pawns to their new positions on the next round's tiles
				var pawns = get_tree().get_nodes_in_group("all_pawns")
				
				for pawn in pawns:
					if (is_instance_valid(pawn)):
						for tile in tiles:
							var tileRound = int(tile.name.get_slice("-", 0))
							if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
								tween.interpolate_property(pawn, "position", pawn.position, tile.position, 0.2, 0, 2, 0)
								tween.start()
								yield($Tween, "tween_completed")
								break
				
				$RollButton.show()
			
			# incrementing the current player at the end of a move, after everything has been updated and is ready for the next turn
			var increment = 0
			while(currentPlayer == "dead" || increment == 0):
				if (currentIndex < 3):
					currentIndex += 1
				else:
					currentIndex = 0
				currentPlayer = colors[currentIndex]
				increment = 1

func revive(): # called to check if the revive should happen or not (technically could be put directly in the tile signal method)
	yield(get_tree(), "idle_frame")
	var pawn = get_node(currentPawn)
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	colorCount = 0
	for forPawn in pawns:
		if (forPawn.color == pawn.color && !forPawn.is_queued_for_deletion()):
			colorCount += 1
	if (colorCount < 4 && gameRound < 4): # you can't revive on the last round
		$ReviveButton.show() # shows the option to revive if there is space for another pawn of the color
		yield(self, "buttonsFinished") # waits for the button function to be done

func _on_FlipButton_pressed(): # when the flip to kill option is chosen
	# hides buttons
	$FlipButton.hide()
	$SkipButton.hide()
	
	# chooses the flip, displays the info, queues the correct pawn for deletion, and waits for one frame to delete the pawn
	var flip = randi() % 2 + 1
	
	yield(get_tree().create_timer(0.5), "timeout") # just to see what's happening easier
	
	$FlipDisplay.playing = true
	yield(get_tree().create_timer(2), "timeout")
	$FlipDisplay.playing = false
	$FlipDisplay.frame = flip - 1
	
	if (flip == 1):
		oppositePawn.get_node("AnimatedSprite").animation = oppositePawn.color + "-Dead"
		oppositePawn.get_node("AnimatedSprite").playing = true
		yield(get_tree().create_timer(2), "timeout")
		oppositePawn.get_node("AnimatedSprite").playing = false
		oppositePawn.get_node("AnimatedSprite").animation = oppositePawn.color
		
		oppositePawn.queue_free()
		yield(get_tree(), "idle_frame")
	else:
		get_node(currentPawn).get_node("AnimatedSprite").animation = get_node(currentPawn).color + "-Dead"
		get_node(currentPawn).get_node("AnimatedSprite").playing = true
		yield(get_tree().create_timer(2), "timeout")
		get_node(currentPawn).get_node("AnimatedSprite").playing = false
		get_node(currentPawn).get_node("AnimatedSprite").animation = get_node(currentPawn).color
		
		get_node(currentPawn).queue_free()
		yield(get_tree(), "idle_frame")
	
	emit_signal("buttonsFinished", "flipped") # emits signal saying that the buttons are done

func _on_ReviveButton_pressed(): # when the revive options is chosen
	var pawn = get_node(currentPawn)
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	
	# flips to see if the revive happens, and does corresponding changes
	var flip = randi() % 2 + 1
	
	$FlipDisplay.playing = true
	yield(get_tree().create_timer(2), "timeout")
	$FlipDisplay.playing = false
	$FlipDisplay.frame = flip - 1
	
	if (flip == 1): # if the flip is heads
		# creates a new pawn and sets the values
		var newPawn = pawn_scene.instance()
		newPawn.name = pawn.color + str(colorCount + 1)
		newPawn.color = pawn.color
		newPawn.connect("clicked", self, "_on_Pawn_clicked")
		var defaultPos = Vector2(0, 0)
		newPawn.position = defaultPos
		
		# sets the new pawn's starting position
		for tile in tiles:
			var tileRound = int(tile.name.get_slice("-", 0))
			if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
				newPawn.position = tile.position
				break
		
		if (newPawn.position == defaultPos):
			for tile in tiles:
				var tileRound = int(tile.name.get_slice("-", 0))
				if (pawnCheck(tile.name) == null && tileRound == gameRound):
					newPawn.position = tile.position
					break
		
		if (newPawn.position != defaultPos):
			add_child(newPawn)
			
			newPawn.get_node("AnimatedSprite").speed_scale = 2
			newPawn.get_node("AnimatedSprite").playing = true
			yield(get_tree().create_timer(1), "timeout")
			newPawn.get_node("AnimatedSprite").playing = false
			newPawn.get_node("AnimatedSprite").speed_scale = 1
			newPawn.get_node("AnimatedSprite").frame = 0
	
	# hides buttons and emits the signal saying that the buttons are done
	$ReviveButton.hide()
	$SkipButton.hide()
	emit_signal("buttonsFinished", "revived")

func _on_SkipButton_pressed(): # if the player chooses to skip instead of flipping
	# hides all the buttons and emits the signal saying that the buttons are done
	$FlipButton.hide()
	$ReviveButton.hide()
	$SkipButton.hide()
	emit_signal("buttonsFinished", "skipped")

func _on_PlayAgain_pressed():
	get_tree().reload_current_scene()
	emit_signal("buttonsFinished", "playagain")

func _on_MainMenu_pressed():
	$PlayAgain.hide()
	$MainMenu.hide()
	emit_signal("buttonsFinished", "mainmenu")
	get_tree().change_scene("res://Menu/Menu.tscn")

func pawnCheck(tile): # gets the pawn on the given tile name, if it doesn't exist, then it returns null
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (get_node(tile).position == pawn.position):
			return pawn
	
	return null

func tileCheck(pawn): # gets the tile that the given pawn name is on, if it doesn't exist (it should), then it returns null
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (get_node(pawn).position == tile.position):
			return tile
	
	return null

func updateColors(): # updates the current players based on if there are any pawns alive
	var colorsLeft = [false, false, false, false] # array to see which players are alive
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (!pawn.is_queued_for_deletion()): # to make sure the pawn isn't being deleted
			# checks if the pawn is a certain color, to see if the color has any pawns alive
			if (pawn.color == "Blue"):
				colorsLeft[0] = true
			elif (pawn.color == "Red"):
				colorsLeft[1] = true
			elif (pawn.color == "Yellow"):
				colorsLeft[2] = true
			elif (pawn.color == "Green"):
				colorsLeft[3] = true
	
	# updates the remaining colors array based on which players are alive
	# also counts the amount of remaining players left in the game
	var i = 0
	var remainingPlayers = 0
	for color in colorsLeft:
		if (color == false):
			colors[i] = "dead"
		else:
			remainingPlayers += 1
		i += 1
	
	if (remainingPlayers == 1): # if there is one player left, they win
		call_deferred("gameOver", "winner")
	elif (remainingPlayers == 0): # if there are no players left, it is a draw
		call_deferred("gameOver", "allDead")

func gameOver(reason): # called when the game ends, taking the reason that the game ended
	$RollButton.hide()
	
	yield(get_tree().create_timer(1), "timeout") # just to see what's happening easier
	
	stopAudio = true
	
	for child in self.get_children():
		if (child.name != "Tween" && child.name != "Background" && child.name != "BGMusic"):
			child.hide()
	
	$EndingDisplay.show()
	if (reason == "winner"):
		var winner = ""
		for color in colors:
			if (color != "dead"):
				winner = color
		$EndingDisplay.texture = load("res://Assets/" + winner + "-Winner.png")
	else:
		$EndingDisplay.texture = load("res://Assets/Draw.png")
	
	$PlayAgain.show()
	$MainMenu.show()
	
	yield(self, "buttonsFinished")

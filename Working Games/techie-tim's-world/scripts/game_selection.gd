extends Control

#@onready var tim_sprite = $MainContainer/ContentContainer/LeftSide/TimCharacter/TimSprite


# Game 1: Techie Tim's Programming Maze
func _on_game1_pressed():
	print("🧩 Starting Programming Maze...")
	if ResourceLoader.exists("res://Scenes/minigame_1.tscn"):
		get_tree().change_scene_to_file("res://Scenes/minigame_1.tscn")
	else:
		print("❌ minigame_1.tscn not found!")
		show_error("Programming Maze game not found!")

# Game 2: Debug the Word Bot
func _on_game2_pressed():
	print("🤖 Starting Debug the Word Bot...")
	if ResourceLoader.exists("res://Scenes/minigame_2.tscn"):
		get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")
	else:
		print("❌ minigame_2.tscn not found!")
		show_error("Debug the Word Bot game not found!")

# Game 3: Tim's Password Decoder
func _on_game3_pressed():
	print("🔐 Starting Password Decoder...")
	if ResourceLoader.exists("res://Scenes/minigame_3.tscn"):
		get_tree().change_scene_to_file("res://Scenes/minigame_3.tscn")
	else:
		print("❌ minigame_3.tscn not found!")
		show_error("Password Decoder game not found!")

# Back to Main Menu
func _on_back_pressed():
	print("🏠 Going back to Main Menu...")
	if ResourceLoader.exists("res://Scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		print("❌ main_menu.tscn not found!")
		show_error("Main menu not found!")

# Simple error display
func show_error(message: String):
	print("Error: ", message)
	# You could add a popup or notification here if needed

# Keyboard shortcuts for quick navigation
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_game1_pressed()
			KEY_2:
				_on_game2_pressed()
			KEY_3:
				_on_game3_pressed()
			KEY_ESCAPE, KEY_B:
				_on_back_pressed()

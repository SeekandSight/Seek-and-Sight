extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the Start Game button to the scene transition function
	var start_button = $Panel/VBoxContainer2/VBoxContainer/StartButton
	start_button.pressed.connect(_on_start_button_pressed)
	
	# You can also connect other buttons here if needed
	var instruction_button = $Panel/VBoxContainer2/VBoxContainer/InstructionButton
	instruction_button.pressed.connect(_on_instruction_button_pressed)
	
	var settings_button = $Panel/VBoxContainer2/VBoxContainer/Settings
	settings_button.pressed.connect(_on_settings_button_pressed)

# Function called when Start Game button is pressed
func _on_start_button_pressed():
	# Change to minigame_1 scene
	get_tree().change_scene_to_file("res://Scenes/minigame_1.tscn")

# Function called when Instructions button is pressed
func _on_instruction_button_pressed():
	# You can add instruction functionality here
	print("Instructions button pressed")

# Function called when Settings button is pressed
func _on_settings_button_pressed():
	# You can add settings functionality here
	print("Settings button pressed")

extends Control

func _ready():
	# Connect the main menu buttons
	$Panel/VBoxContainer2/VBoxContainer/StartButton.pressed.connect(_on_start_game_pressed)
	$Panel/VBoxContainer2/VBoxContainer/InstructionButton.pressed.connect(_on_instructions_pressed)
	$Panel/VBoxContainer2/VBoxContainer/SettingButton.pressed.connect(_on_settings_pressed)

func _on_start_game_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

func _on_instructions_pressed():
	# Show instructions or go to instructions scene
	print("Instructions pressed")

func _on_settings_pressed():
	# Show settings or go to settings scene
	print("Settings pressed")

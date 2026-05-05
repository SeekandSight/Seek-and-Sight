extends Node2D


@onready var student_name_edit: LineEdit = $UI/StudentNameEdit
@onready var start_button: Button = $UI/ButtonContainer/StartButton
@onready var options_button: Button = $UI/ButtonContainer/OptionsButton # Add this button to your scene
@onready var quit_button: Button = $UI/ButtonContainer/QuitButton     # Add this button to your scene


func _ready() -> void:
	pass


func _on_start_button_pressed() -> void:
	# 1. Get the student's name from the LineEdit node.
	var student_name = student_name_edit.text
	
	# 2. Set the student ID in global analytics singleton.
	Analytics.set_student_id(student_name)
	
	# 3. Reset all other analytics data for the new session.
	Analytics.reset_analytics()
	
	# 4. Proceed to the first level of the game.
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene2_WordTower.tscn")


func _on_options_button_pressed() -> void:
	# Go to the new options menu scene.
	# Make sure the path to your options scene is correct.
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/OptionsMenu.tscn")


func _on_quit_button_pressed() -> void:
	# This will safely close the game application.
	get_tree().quit()

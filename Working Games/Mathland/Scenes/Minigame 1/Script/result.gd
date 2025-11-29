extends Node2D

@onready var game_name_label = $UI/Panel/GameName
@onready var grade_level_label = $UI/Panel/GradeLevel
@onready var time_label = $UI/Panel/TimeLabel
@onready var correct_label = $UI/Panel/CorrectLabel
@onready var incorrect_label = $UI/Panel/IncorrectLabel
@onready var encouragement_label = $UI/Panel/EncouragementLabel
@onready var menu_button = $UI/Panel/MenuButton
@onready var play_again_button = $UI/Panel/PlayAgainButton

func _ready():
	menu_button.pressed.connect(_on_menu_button_pressed)
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	
	display_results()

func display_results():
	var results = GameData.game_history
	
	if results.is_empty():
		return
	
	# Get the last result
	var last_result = results[results.size() - 1]
	
	# Display game info
	game_name_label.text = last_result.get("game_name", "Unknown Game")
	grade_level_label.text = "Grade: " + last_result.get("grade_level", "Unknown")
	
	# Display time
	var time = last_result.get("time", 0)
	var minutes = time / 60
	var seconds = time % 60
	time_label.text = "Time: %d:%02d" % [minutes, seconds]
	
	# Display scores
	var correct = last_result.get("correct", 0)
	var incorrect = last_result.get("incorrect", 0)
	var total = last_result.get("total", 0)
	
	correct_label.text = "Correct: %d / %d" % [correct, total]
	incorrect_label.text = "Incorrect: %d" % incorrect
	
	# Show encouragement
	encouragement_label.text = get_encouragement_message(correct, total)

func get_encouragement_message(correct: int, total: int) -> String:
	var percentage = (float(correct) / float(total)) * 100.0 if total > 0 else 0
	
	if percentage == 100:
		return "Perfect score! Amazing work!"
	elif percentage >= 80:
		return "Excellent job! You're doing great!"
	elif percentage >= 60:
		return "Good effort! Keep practicing!"
	else:
		return "Great try! Practice makes perfect!"

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu/Scene/MainMenu.tscn")

func _on_play_again_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Minigame 1/Scene/number_match.tscn")

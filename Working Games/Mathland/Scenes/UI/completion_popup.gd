extends CanvasLayer

signal level_select_pressed
signal main_menu_pressed
signal next_level_pressed

@onready var title_label = $PopupPanel/VBox/TitleLabel
@onready var message_label = $PopupPanel/VBox/MessageLabel
@onready var stats_label = $PopupPanel/VBox/StatsLabel
@onready var level_select_button = $PopupPanel/VBox/ButtonsContainer/LevelSelectButton
@onready var main_menu_button = $PopupPanel/VBox/ButtonsContainer/MainMenuButton
@onready var next_level_button = $PopupPanel/VBox/ButtonsContainer/NextLevelButton

func _ready():
	level_select_button.pressed.connect(_on_level_select_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)

func show_level_complete(level: int, score: int, total: int, time: int, has_next_level: bool):
	title_label.text = "Level " + str(level) + " Complete!"
	message_label.text = "Great job! You finished the level."
	
	var minutes = time / 60
	var seconds = time % 60
	var accuracy = (float(score) / float(total) * 100.0) if total > 0 else 0
	
	stats_label.text = "Score: %d/%d (%.1f%%)\nTime: %d:%02d" % [score, total, accuracy, minutes, seconds]
	
	# Show/hide next level button
	next_level_button.visible = has_next_level
	
	show()

func show_game_complete(total_score: int, total_questions: int, total_time: int):
	title_label.text = "Game Complete!"
	message_label.text = "Congratulations! You finished all levels!"
	
	var minutes = total_time / 60
	var seconds = total_time % 60
	var accuracy = (float(total_score) / float(total_questions) * 100.0) if total_questions > 0 else 0
	
	stats_label.text = "Final Score: %d/%d (%.1f%%)\nTotal Time: %d:%02d" % [total_score, total_questions, accuracy, minutes, seconds]
	
	# Hide next level button for game complete
	next_level_button.visible = false
	
	show()

func _on_level_select_pressed():
	level_select_pressed.emit()

func _on_main_menu_pressed():
	main_menu_pressed.emit()

func _on_next_level_pressed():
	next_level_pressed.emit()

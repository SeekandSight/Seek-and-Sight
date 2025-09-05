extends Control

func _ready():
	# Connect the game buttons
	$Panel/VBoxContainer/AnimalMatchButton.pressed.connect(_on_animal_match_pressed)
	$Panel/VBoxContainer2/WordSearchButton.pressed.connect(_on_word_search_pressed)
	$Panel/VBoxContainer3/WordSortButton.pressed.connect(_on_word_sort_pressed)

func _on_animal_match_pressed():
	get_tree().change_scene_to_file("res://Scenes/minigame1.tscn")

func _on_word_search_pressed():
	get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")

func _on_word_sort_pressed():
	get_tree().change_scene_to_file("res://Scenes/minigame_3.tscn")

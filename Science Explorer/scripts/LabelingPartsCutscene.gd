extends Control

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Scene3_LabelingPartsGame.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Scene1_ScienceMainMenu.tscn")

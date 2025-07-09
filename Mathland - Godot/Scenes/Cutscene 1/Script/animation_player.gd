extends AnimationPlayer
	
func _on_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://Scenes/Minigame 1/Scene/minigame1.tscn")


func _on_demo_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Minigame 1/Scene/minigame1.tscn")

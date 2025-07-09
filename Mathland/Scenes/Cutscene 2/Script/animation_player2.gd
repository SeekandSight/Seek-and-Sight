extends AnimationPlayer

func _on_animation_finished(_anim_name: StringName):
	print("Animation Complete")
	get_tree().change_scene_to_file("res://Scenes/Minigame 2/Scene/minigame_2.tscn")

func _on_demo_2_pressed():
	print("Button Pressed")
	get_tree().change_scene_to_file("res://Scenes/Minigame 2/Scene/minigame_2.tscn")

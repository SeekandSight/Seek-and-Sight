extends Control

@export var correct_name: String = ""
@onready var correct_sound_player = $CorrectSound
@onready var incorrect_sound_player = $IncorrectSound
@onready var tween := create_tween()


var correct_sounds = [
	preload("res://Audio/Mathwizard Positive.wav"),
	preload("res://Audio/Mathwizard 100%.wav")
]

var incorrect_sounds = [
	preload("res://Audio/Mathwizard Almost.wav"),
	preload("res://Audio/Mathwizard Try Again.wav")
]

var shape_map = {
"circle":"res://Images/Circle.png",
"diamond":"res://Images/Diamond.png",
"heart":"res://Images/Heart.png",
"square":"res://Images/Square.png",
"star":"res://Images/Star.png",
"triangle":"res://Images/Triangle.png"
}


func _ready():
	var shape_texture_path = shape_map.get(correct_name, "")
	if shape_texture_path != "":
		var tex = load(shape_texture_path)
		$Shape.texture = tex
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))
		
		# SCALE DOWN based on original size
		var target_size = Vector2(110, 110)  # adjust to fit your design
		var original_size = tex.get_size()
		var scale = target_size / original_size
		$Shape.scale = scale

func _on_mouse_entered():
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)

func _on_mouse_exited():
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.1)


func play_correct_sound():
	var sound = correct_sounds[randi() % correct_sounds.size()]
	correct_sound_player.stream = sound
	correct_sound_player.play()

func play_incorrect_sound():
	var sound = incorrect_sounds[randi() % incorrect_sounds.size()]
	incorrect_sound_player.stream = sound
	incorrect_sound_player.play()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("value")

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data["value"] == correct_name:
		modulate = Color.GREEN
		play_correct_sound()
		get_parent().get_parent()._on_word_solved()
		var slot = data["source"]
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.position = global_position + Vector2(500, 500)
	else:
		modulate = Color.RED
		play_incorrect_sound()
		await get_tree().create_timer(1.0).timeout
		modulate = Color.WHITE

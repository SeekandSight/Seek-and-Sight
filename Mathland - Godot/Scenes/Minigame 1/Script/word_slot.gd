extends Control

@export var correct_number: int = 1
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

var word_map = {
	1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
	6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten"
}


func _ready():
	$Word.text = word_map.get(correct_number, " ??? ")
	$Word.add_theme_constant_override("margin_left", 50)
	$Word.add_theme_constant_override("margin_right", 50)
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

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
	if data["value"] == correct_number:
		$Word.text = "✓ " + $Word.text
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

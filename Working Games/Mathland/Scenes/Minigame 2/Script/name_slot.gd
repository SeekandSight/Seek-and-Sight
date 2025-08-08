extends Control

@export var value: String = ""
@onready var tween := create_tween()

func _ready():
	$Name.text = value
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


func _get_drag_data(_pos):
	var drag_data = {
		"value": value,
		"source": self
	}

	var preview = Label.new()
	preview.text = value
	preview.add_theme_font_size_override("font_size", 54)
	set_drag_preview(preview)

	return drag_data

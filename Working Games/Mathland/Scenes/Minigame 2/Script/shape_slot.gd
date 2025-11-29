extends Panel

signal match_made(is_correct: bool)
signal shape_removed

var shape_name: String = ""
var correct_name: String = ""
var dragging = false
var drag_enabled = false
var stored_position = Vector2.ZERO
var matched = false

var shape_map = {
	"circle": "res://Images/Circle.png",
	"diamond": "res://Images/Diamond.png",
	"heart": "res://Images/Heart.png",
	"square": "res://Images/Square.png",
	"star": "res://Images/Star.png",
	"triangle": "res://Images/Triangle.png",
	"pentagon": "res://Images/Pentagon.png",
	"hexagon": "res://Images/Hexagon.png",
	"oval": "res://Images/Oval.png",
	"rectangle": "res://Images/Rectangle.png"
}

@onready var shape_sprite: Sprite2D = null

func _ready():
	custom_minimum_size = Vector2(100, 100)

	# Create the shape sprite
	shape_sprite = Sprite2D.new()
	add_child(shape_sprite)
	shape_sprite.position = size / 2

	await get_tree().process_frame
	update_stored_position()

func set_shape(shape: String):
	shape_name = shape
	correct_name = shape

	var shape_texture_path = shape_map.get(shape, "")
	if shape_texture_path != "" and FileAccess.file_exists(shape_texture_path):
		var tex = load(shape_texture_path)
		if shape_sprite:
			shape_sprite.texture = tex
			# Scale down to fit
			var target_size = Vector2(80, 80)
			var original_size = tex.get_size()
			var scale_factor = target_size / original_size
			shape_sprite.scale = scale_factor

func enable_dragging():
	drag_enabled = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func disable_dragging():
	drag_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_stored_position():
	await get_tree().process_frame
	stored_position = global_position

func _get_drag_data(_at_position):
	if not drag_enabled or matched:
		return null

	dragging = true
	var data = {
		"shape_name": shape_name,
		"source": self
	}

	# Create preview
	var preview = Panel.new()
	preview.custom_minimum_size = custom_minimum_size
	var preview_sprite = Sprite2D.new()
	preview.add_child(preview_sprite)
	preview_sprite.position = custom_minimum_size / 2
	if shape_sprite and shape_sprite.texture:
		preview_sprite.texture = shape_sprite.texture
		preview_sprite.scale = shape_sprite.scale
	preview.modulate = Color(1, 1, 1, 0.7)
	set_drag_preview(preview)

	# Hide original while dragging
	modulate.a = 0.3

	return data

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		dragging = false
		if not matched:
			modulate.a = 1.0

func mark_matched():
	matched = true
	drag_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.GREEN

	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.tween_callback(func():
		shape_removed.emit()
		queue_free()
	)

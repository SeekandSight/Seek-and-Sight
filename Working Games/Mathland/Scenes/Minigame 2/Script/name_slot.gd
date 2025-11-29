extends Panel

var name_text: String = ""
var matched = false

@onready var label: Label = null

func _ready():
	custom_minimum_size = Vector2(120, 80)

	# Create label
	label = Label.new()
	add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = custom_minimum_size
	label.position = Vector2.ZERO

	# Load font
	if FileAccess.file_exists("res://Orbitron/static/Orbitron-Bold.ttf"):
		var font = load("res://Orbitron/static/Orbitron-Bold.ttf")
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 24)

func set_name_text(text: String):
	name_text = text
	if label:
		label.text = text.capitalize()

func _can_drop_data(_at_position, data):
	if matched:
		return false
	return typeof(data) == TYPE_DICTIONARY and data.has("shape_name")

func _drop_data(_at_position, data):
	if matched:
		return

	var shape_name = data["shape_name"]
	var source = data["source"]

	print("Dropped ", shape_name, " on ", name_text)

	if shape_name == name_text:
		# Correct match
		print("Correct match!")
		matched = true
		modulate = Color.GREEN

		if source.has_method("mark_matched"):
			source.mark_matched()

		if source.has_method("match_made"):
			source.match_made.emit(true)

		# Fade out after success
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
		tween.tween_callback(queue_free)
	else:
		# Incorrect match
		print("Incorrect match!")
		var original_color = modulate
		modulate = Color.RED

		if source.has_method("match_made"):
			source.match_made.emit(false)

		# Flash red then back to normal
		var tween = create_tween()
		tween.tween_property(self, "modulate", original_color, 0.5).set_delay(0.3)

extends Control

signal match_made(is_correct: bool)
signal number_removed()

var dragging = false
var drag_offset = Vector2.ZERO
var stored_global_position = Vector2.ZERO
var number_value = 0
var number_word = ""
var is_returning = false
var can_drag = false

@onready var number_label = get_node_or_null("NumberLabel")
@onready var background = get_node_or_null("NeonBorder/InnerArea")
@onready var neon_border = get_node_or_null("NeonBorder")

func _ready():
	for i in range(5):
		await get_tree().process_frame
	
	update_stored_position()
	
	print("Number ", number_value, " stored at global position: ", stored_global_position)

func update_stored_position():
	stored_global_position = global_position
	print("Number ", number_value, " position updated to: ", stored_global_position)

func set_number(num: int, word: String):
	number_value = num
	number_word = word
	
	if not number_label:
		number_label = get_node_or_null("NumberLabel")
	
	if number_label:
		number_label.text = str(num)

func enable_dragging():
	can_drag = true

func disable_dragging():
	can_drag = false
	if dragging:
		dragging = false
		scale = Vector2(1.0, 1.0)
		z_index = 0

func _gui_input(event):
	if is_returning or not can_drag:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				z_index = 100000
				scale = Vector2(1.15, 1.15)
				
				if neon_border:
					neon_border.color = Color(0.8, 1, 1, 1)
			else:
				dragging = false
				scale = Vector2(1.0, 1.0)
				
				if neon_border:
					neon_border.color = Color(0.3, 0.6, 1, 1)
				
				check_drop()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() - drag_offset

func check_drop():
	var mouse_pos = get_global_mouse_position()
	var drop_zones = get_tree().get_nodes_in_group("drop_zones")
	
	for zone in drop_zones:
		var zone_rect = Rect2(zone.global_position, zone.size)
		if zone_rect.has_point(mouse_pos) and not zone.is_completed:
			if zone.word_value == number_word:
				match_made.emit(true)
				
				if neon_border:
					neon_border.color = Color(0.3, 1, 0.5, 1)
				
				var tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
				tween.tween_property(self, "modulate", Color(0.5, 1, 0.5, 0), 0.3)
				await tween.finished
				
				zone.mark_completed()
				
				number_removed.emit()
				
				queue_free()
				return
			else:
				match_made.emit(false)
				flash_red()
				return
	
	return_to_stored_position()

func flash_red():
	is_returning = true
	z_index = 100000
	
	if background:
		background.color = Color(0.4, 0.05, 0.1, 1)
	if neon_border:
		neon_border.color = Color(1, 0.2, 0.2, 1)
	
	var current = global_position
	var shake = create_tween()
	shake.tween_property(self, "global_position", current + Vector2(-10, 0), 0.04)
	shake.tween_property(self, "global_position", current + Vector2(10, 0), 0.04)
	shake.tween_property(self, "global_position", current + Vector2(-10, 0), 0.04)
	shake.tween_property(self, "global_position", current, 0.04)
	
	await shake.finished
	
	if background:
		background.color = Color(0.08, 0.12, 0.25, 1)
	if neon_border:
		neon_border.color = Color(0.3, 0.6, 1, 1)
	
	return_to_stored_position()

func return_to_stored_position():
	is_returning = true
	z_index = 100000
	
	print("Returning ", number_value, " to stored position: ", stored_global_position)
	
	global_position = stored_global_position
	
	z_index = 0
	scale = Vector2(1.0, 1.0)
	is_returning = false
	
	print("  Returned to: ", global_position)

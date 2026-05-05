extends Control

signal level_selected(level: int)

var level_number = 1
var is_unlocked = false
var is_completed = false

@onready var level_label = get_node_or_null("LevelLabel")
@onready var status_label = get_node_or_null("StatusLabel")
@onready var background = get_node_or_null("Border/InnerArea")
@onready var border = get_node_or_null("Border")
@onready var button_area = self

func _ready():
	gui_input.connect(_on_gui_input)

func setup_level(level: int, unlocked: bool, completed: bool):
	level_number = level
	is_unlocked = unlocked
	is_completed = completed
	
	if level_label:
		level_label.text = str(level)
	
	update_appearance()

func update_appearance():
	if is_completed:
		# Completed - Green
		if background:
			background.color = Color(0.1, 0.3, 0.15, 1)
		if border:
			border.color = Color(0.3, 1, 0.4, 1)
		if level_label:
			level_label.modulate = Color(0.5, 1, 0.6, 1)
		if status_label:
			status_label.text = "COMPLETE"
			status_label.visible = true
			status_label.modulate = Color(0.5, 1, 0.6, 1)
	elif is_unlocked:
		# Unlocked - Blue
		if background:
			background.color = Color(0.08, 0.12, 0.25, 1)
		if border:
			border.color = Color(0.3, 0.6, 1, 1)
		if level_label:
			level_label.modulate = Color(0.5, 0.8, 1, 1)
		if status_label:
			status_label.visible = false
	else:
		# Locked - Gray
		if background:
			background.color = Color(0.15, 0.15, 0.15, 1)
		if border:
			border.color = Color(0.3, 0.3, 0.3, 1)
		if level_label:
			level_label.modulate = Color(0.4, 0.4, 0.4, 1)
		if status_label:
			status_label.text = "LOCKED"
			status_label.visible = true
			status_label.modulate = Color(0.5, 0.5, 0.5, 1)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_unlocked:
				level_selected.emit(level_number)
				print("Selected level: ", level_number)
			else:
				print("Level ", level_number, " is locked!")

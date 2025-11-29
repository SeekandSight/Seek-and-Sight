extends Node2D

@onready var number_match_button = get_node_or_null("UI/GamesPanel/NumberMatchButton")
@onready var shape_match_button = get_node_or_null("UI/GamesPanel/ShapeMatchButton")
@onready var count_up_button = get_node_or_null("UI/GamesPanel/CountUpButton")

func _ready():
	print("=== Main Menu Loading ===")
	
	# Load game data
	if GameData:
		GameData.load_all_data()
		print("GameData loaded")
	else:
		push_warning("GameData autoload not found!")
	
	# Connect buttons if they exist
	if number_match_button:
		number_match_button.pressed.connect(_on_number_match_pressed)
		print("Number Match button connected")
	else:
		push_warning("NumberMatchButton not found!")
	
	if shape_match_button:
		shape_match_button.pressed.connect(_on_shape_match_pressed)
	
	if count_up_button:
		count_up_button.pressed.connect(_on_count_up_pressed)
	
	print("=== Main Menu Ready ===")

func _on_number_match_pressed():
	print("Opening Number Match Level Select...")
	# NEW: Go to level select screen instead of directly to game
	get_tree().change_scene_to_file("res://Scenes/LevelSelect/Scenes/level_select.tscn")

func _on_shape_match_pressed():
	print("Shape Match coming soon...")

func _on_count_up_pressed():
	print("Count Up coming soon...")

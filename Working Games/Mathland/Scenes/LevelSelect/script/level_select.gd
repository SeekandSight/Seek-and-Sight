extends Node2D

@onready var background = get_node_or_null("Background")
@onready var title_label = get_node_or_null("UI/TitleLabel")
@onready var levels_container = get_node_or_null("UI/LevelsPanel/LevelsGrid")
@onready var back_button = get_node_or_null("UI/BackButton")
@onready var reset_button = get_node_or_null("UI/ResetButton")

var current_grade = "Kindergarten"
var max_levels = 15

var LevelButton = preload("res://Scenes/LevelSelect/Scenes/level_button.tscn")

func _ready():
	print("=== Level Select Loading ===")
	
	if GameData:
		current_grade = GameData.player_profile["grade_level"]
		
		# Get max levels for current grade
		if current_grade == "Kindergarten":
			max_levels = 15
		elif current_grade == "1st Grade":
			max_levels = 20
		elif current_grade == "2nd Grade":
			max_levels = 25
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	
	populate_level_buttons()
	print("=== Level Select Ready ===")

func populate_level_buttons():
	if not levels_container:
		push_error("LevelsGrid not found!")
		return
	
	# Clear existing buttons
	for child in levels_container.get_children():
		child.queue_free()
	
	var highest_unlocked = GameData.get_highest_unlocked_level()
	
	print("Creating buttons for ", max_levels, " levels")
	print("Highest unlocked: ", highest_unlocked)
	
	# Create level buttons
	for level in range(1, max_levels + 1):
		var button = LevelButton.instantiate()
		levels_container.add_child(button)
		
		await get_tree().process_frame
		
		var is_unlocked = GameData.is_level_unlocked(level)
		var is_completed = GameData.is_level_completed(level)
		
		button.setup_level(level, is_unlocked, is_completed)
		button.level_selected.connect(_on_level_selected)

func _on_level_selected(level: int):
	print("Level ", level, " selected")
	
	# Set the starting level in game settings
	if GameData:
		GameData.current_game_settings["selected_level"] = level
	
	# Load the game
	get_tree().change_scene_to_file("res://Scenes/Minigame 1/Scene/number_match.tscn")

func _on_back_pressed():
	print("Returning to main menu")
	get_tree().change_scene_to_file("res://Scenes/MainMenu/Scene/MainMenu.tscn")

func _on_reset_pressed():
	print("Resetting level progress")
	GameData.reset_level_progress()
	populate_level_buttons()

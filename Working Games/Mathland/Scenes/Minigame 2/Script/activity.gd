extends Node2D

var game_active = false
var elapsed_time = 0
var correct_matches = 0
var incorrect_matches = 0
var current_level = 1
var consecutive_correct = 0
var total_matches_needed = 0
var last_level_shapes = []

var difficulty_settings = {
	"Kindergarten": {
		"max_level": 15,
		"shapes_per_level": 4
	},
	"1st Grade": {
		"max_level": 20,
		"shapes_per_level": 5
	},
	"2nd Grade": {
		"max_level": 25,
		"shapes_per_level": 6
	}
}

var all_shapes = ["circle", "square", "triangle", "heart", "diamond", "star", "pentagon", "hexagon", "oval", "rectangle"]

var current_grade = "Kindergarten"
var current_shapes = []
var current_names = []
var questions_this_level = 0
var total_questions = 0

@onready var shapes_container = get_node_or_null("UI/ShapeArea/ShapesContainer")
@onready var names_container = get_node_or_null("UI/NameArea/NamesContainer")
@onready var timer_label = get_node_or_null("UI/ControlPanel/TimerLabel")
@onready var play_button = get_node_or_null("UI/ControlPanel/PlayButton")
@onready var menu_button = get_node_or_null("UI/ControlPanel/MenuButton")
@onready var levels_button = get_node_or_null("UI/ControlPanel/LevelsButton")
@onready var level_label = get_node_or_null("UI/GoalArea/LevelLabel")
@onready var score_label = get_node_or_null("UI/GoalArea/ScoreLabel")
@onready var game_timer = get_node_or_null("GameTimer")
@onready var correct_sound = get_node_or_null("CorrectSound")
@onready var incorrect_sound = get_node_or_null("IncorrectSound")

var DraggableShape = preload("res://Scenes/Minigame 2/Scene/shape_slot.tscn")
var DropZoneName = preload("res://Scenes/Minigame 2/Scene/name_slot.tscn")
var CompletionPopup = preload("res://Scenes/UI/completion_popup.tscn")

var popup_instance = null

func _ready():
	print("=== Shape Match Game Starting ===")

	if GameData and GameData.current_game_settings.has("selected_level"):
		current_level = GameData.current_game_settings["selected_level"]
		print("Starting at selected level: ", current_level)
		GameData.current_game_settings.erase("selected_level")

	if not shapes_container or not names_container or not play_button or not menu_button or not game_timer:
		push_error("Required nodes not found!")
		return

	play_button.pressed.connect(_on_play_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	if levels_button:
		levels_button.pressed.connect(_on_levels_button_pressed)
		print("Levels button connected")

	game_timer.timeout.connect(_on_timer_timeout)

	if GameData:
		current_grade = GameData.player_profile["grade_level"]
		print("Grade level: ", current_grade)
	else:
		push_warning("GameData not found, using default grade")

	if correct_sound and FileAccess.file_exists("res://Audio/Mathwizard Positive.wav"):
		correct_sound.stream = load("res://Audio/Mathwizard Positive.wav")
	if incorrect_sound and FileAccess.file_exists("res://Audio/Mathwizard Try Again.wav"):
		incorrect_sound.stream = load("res://Audio/Mathwizard Try Again.wav")

	await setup_new_level()
	print("=== Game Ready - Press Start to Play ===")

func get_level_shapes(level: int) -> Array:
	var shapes_count = difficulty_settings[current_grade]["shapes_per_level"]

	# Adjust difficulty based on level
	if level <= 3:
		shapes_count = min(shapes_count, 4)
	elif level <= 6:
		shapes_count = min(shapes_count, 5)
	elif level <= 9:
		shapes_count = min(shapes_count, 6)

	var available = all_shapes.duplicate()
	available.shuffle()

	# Try to avoid repeating from last level
	var selected = []
	for shape in available:
		if not shape in last_level_shapes and selected.size() < shapes_count:
			selected.append(shape)

	# If we don't have enough, add from all shapes
	while selected.size() < shapes_count:
		for shape in available:
			if not shape in selected:
				selected.append(shape)
				break

	return selected

func setup_new_level():
	if not shapes_container or not names_container:
		push_error("Cannot setup level: containers missing")
		return

	print("\n=== Setting up Level ", current_level, " ===")

	disable_all_draggables()
	clear_container(shapes_container)
	clear_container(names_container)

	current_shapes = get_level_shapes(current_level)
	print("Shapes for level: ", current_shapes)

	last_level_shapes = current_shapes.duplicate()

	current_names = current_shapes.duplicate()
	var shuffled_names = current_names.duplicate()
	shuffled_names.shuffle()
	print("Shuffled names: ", shuffled_names)

	# Create draggable shapes
	for i in range(current_shapes.size()):
		var shape_name = current_shapes[i]

		var draggable = DraggableShape.instantiate()
		shapes_container.add_child(draggable)
		await get_tree().process_frame

		draggable.set_shape(shape_name)
		draggable.match_made.connect(_on_match_made)
		draggable.shape_removed.connect(_on_shape_removed)
		draggable.disable_dragging()

	# Create drop zones for names
	for i in range(shuffled_names.size()):
		var name = shuffled_names[i]

		var drop_zone = DropZoneName.instantiate()
		names_container.add_child(drop_zone)
		await get_tree().process_frame

		drop_zone.set_name_text(name)

	questions_this_level = 0
	total_matches_needed = current_shapes.size()
	update_level_display()

	await get_tree().process_frame
	if game_active:
		print("Re-enabling dragging after level setup")
		enable_all_draggables()

	print("=== Level setup complete - Need ", total_matches_needed, " correct matches ===\n")

func clear_container(container):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func enable_all_draggables():
	if shapes_container:
		await get_tree().process_frame
		for child in shapes_container.get_children():
			if child.has_method("enable_dragging"):
				child.enable_dragging()
		print("All draggables enabled")

func disable_all_draggables():
	if shapes_container:
		for child in shapes_container.get_children():
			if child.has_method("disable_dragging"):
				child.disable_dragging()

func _on_shape_removed():
	print("Shape removed, updating remaining positions...")

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if shapes_container:
		for child in shapes_container.get_children():
			if child.has_method("update_stored_position"):
				child.update_stored_position()

	print("All positions updated!")

func _on_play_button_pressed():
	if not game_active:
		start_game()
	else:
		pause_game()

func start_game():
	game_active = true
	if play_button:
		play_button.text = "Pause"
	if game_timer:
		game_timer.start()

	await get_tree().process_frame
	enable_all_draggables()
	print("Game started!")

func pause_game():
	game_active = false
	if play_button:
		play_button.text = "Start"
	if game_timer:
		game_timer.stop()

	disable_all_draggables()
	print("Game paused!")

func _on_timer_timeout():
	if game_active:
		elapsed_time += 1
		update_timer_display()

func update_timer_display():
	if not timer_label:
		return
	var minutes = elapsed_time / 60
	var seconds = elapsed_time % 60
	timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func update_level_display():
	if level_label:
		level_label.text = "Level: %d" % current_level
	if score_label:
		score_label.text = "Score: %d / %d" % [questions_this_level, total_matches_needed]

func _on_match_made(is_correct: bool):
	if not game_active:
		return

	print("\n=== Match attempt: ", "CORRECT" if is_correct else "INCORRECT", " ===")

	if is_correct:
		correct_matches += 1
		consecutive_correct += 1
		total_questions += 1
		questions_this_level += 1

		print("Correct! This level: ", questions_this_level, "/", total_matches_needed)
		print("Total correct: ", correct_matches)
		print("Consecutive: ", consecutive_correct)

		if correct_sound:
			correct_sound.play()

		update_level_display()

		if consecutive_correct == 3:
			print("3 in a row!")
		elif consecutive_correct == 5:
			print("5 in a row! Amazing!")
		elif consecutive_correct == 10:
			print("10 in a row! Incredible!")

		if questions_this_level >= total_matches_needed:
			print("Level ", current_level, " complete!")

			disable_all_draggables()
			game_active = false
			if game_timer:
				game_timer.stop()

			if GameData:
				GameData.update_level_progress(current_level)

			var settings = difficulty_settings[current_grade]
			if current_level >= settings["max_level"]:
				print("Max level reached!")
				show_game_complete_popup()
			else:
				if current_level % 5 == 0:
					print("Milestone Level ", current_level, " complete!")

				show_level_complete_popup()

	else:
		incorrect_matches += 1
		consecutive_correct = 0
		print("Incorrect. Total wrong: ", incorrect_matches)
		print("Streak reset!")

		if incorrect_sound:
			incorrect_sound.play()

func show_level_complete_popup():
	popup_instance = CompletionPopup.instantiate()
	add_child(popup_instance)

	var settings = difficulty_settings[current_grade]
	var has_next = current_level < settings["max_level"]

	popup_instance.show_level_complete(current_level, questions_this_level, total_matches_needed, elapsed_time, has_next)
	popup_instance.level_select_pressed.connect(_on_popup_level_select)
	popup_instance.main_menu_pressed.connect(_on_popup_main_menu)
	popup_instance.next_level_pressed.connect(_on_popup_next_level)

func show_game_complete_popup():
	popup_instance = CompletionPopup.instantiate()
	add_child(popup_instance)

	popup_instance.show_game_complete(correct_matches, total_questions, elapsed_time)
	popup_instance.level_select_pressed.connect(_on_popup_level_select)
	popup_instance.main_menu_pressed.connect(_on_popup_main_menu)

func _on_popup_level_select():
	save_incomplete_progress()
	get_tree().change_scene_to_file("res://Scenes/LevelSelect/Scenes/level_select.tscn")

func _on_popup_main_menu():
	save_incomplete_progress()
	get_tree().change_scene_to_file("res://Scenes/MainMenu/Scene/MainMenu.tscn")

func _on_popup_next_level():
	if popup_instance:
		popup_instance.queue_free()
		popup_instance = null

	current_level += 1
	elapsed_time = 0
	questions_this_level = 0
	await setup_new_level()
	start_game()

func _on_levels_button_pressed():
	print("Levels button pressed")

	if game_active:
		pause_game()

	save_incomplete_progress()
	get_tree().change_scene_to_file("res://Scenes/LevelSelect/Scenes/level_select.tscn")

func _on_menu_button_pressed():
	print("Menu button pressed")

	if game_active:
		pause_game()

	save_incomplete_progress()
	get_tree().change_scene_to_file("res://Scenes/MainMenu/Scene/MainMenu.tscn")

func save_incomplete_progress():
	if GameData and total_questions > 0:
		var accuracy = (float(correct_matches) / float(total_questions) * 100.0) if total_questions > 0 else 0
		var result = {
			"game_name": "Shape Match",
			"grade_level": current_grade,
			"time": elapsed_time,
			"correct": correct_matches,
			"incorrect": incorrect_matches,
			"total": total_questions,
			"levels_completed": current_level - 1,
			"accuracy": accuracy
		}
		GameData.save_game_result(result)
		print("Progress saved")

extends Node2D

var game_active = false
var elapsed_time = 0
var correct_clicks = 0
var incorrect_clicks = 0
var current_level = 1
var consecutive_correct = 0
var total_questions = 0

var difficulty_settings = {
	"Kindergarten": {
		"max_level": 15,
		"max_number": 10
	},
	"1st Grade": {
		"max_level": 20,
		"max_number": 20
	},
	"2nd Grade": {
		"max_level": 25,
		"max_number": 30
	}
}

var current_grade = "Kindergarten"
var target_number = 0
var current_count = 1
var number_buttons = []

@onready var numbers_grid = get_node_or_null("UI/NumberArea/NumbersGrid")
@onready var timer_label = get_node_or_null("UI/ControlPanel/TimerLabel")
@onready var play_button = get_node_or_null("UI/ControlPanel/PlayButton")
@onready var menu_button = get_node_or_null("UI/ControlPanel/MenuButton")
@onready var levels_button = get_node_or_null("UI/ControlPanel/LevelsButton")
@onready var level_label = get_node_or_null("UI/ControlPanel/LevelLabel")
@onready var game_timer = get_node_or_null("GameTimer")
@onready var correct_sound = get_node_or_null("CorrectSound")
@onready var incorrect_sound = get_node_or_null("IncorrectSound")

var CompletionPopup = preload("res://Scenes/UI/completion_popup.tscn")
var popup_instance = null

func _ready():
	print("=== Counting Game Starting ===")

	if GameData and GameData.current_game_settings.has("selected_level"):
		current_level = GameData.current_game_settings["selected_level"]
		print("Starting at selected level: ", current_level)
		GameData.current_game_settings.erase("selected_level")

	if not numbers_grid or not play_button or not menu_button or not game_timer:
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

	setup_new_level()
	print("=== Game Ready - Press Start to Play ===")

func get_target_number_for_level(level: int) -> int:
	var base_max = difficulty_settings[current_grade]["max_number"]

	# Progressive difficulty
	if level <= 3:
		return min(5 + level, base_max)
	elif level <= 6:
		return min(8 + (level - 3), base_max)
	elif level <= 9:
		return min(12 + (level - 6), base_max)
	else:
		return min(15 + (level - 9), base_max)

func setup_new_level():
	if not numbers_grid:
		push_error("Cannot setup level: grid missing")
		return

	print("\n=== Setting up Level ", current_level, " ===")

	clear_container(numbers_grid)
	number_buttons.clear()

	target_number = get_target_number_for_level(current_level)
	current_count = 1

	print("Target number for level ", current_level, ": ", target_number)

	# Create shuffled numbers
	var numbers = []
	for i in range(1, target_number + 1):
		numbers.append(i)
	numbers.shuffle()

	# Create buttons
	for num in numbers:
		var button = Button.new()
		button.text = str(num)
		button.custom_minimum_size = Vector2(100, 80)

		# Load font
		if FileAccess.file_exists("res://Orbitron/static/Orbitron-Bold.ttf"):
			var font = load("res://Orbitron/static/Orbitron-Bold.ttf")
			button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 36)

		button.disabled = true
		button.pressed.connect(_on_number_pressed.bind(num, button))

		numbers_grid.add_child(button)
		number_buttons.append(button)

	update_level_display()
	print("=== Level setup complete ===\n")

func clear_container(container):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

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

	# Enable all buttons
	for button in number_buttons:
		button.disabled = false

	print("Game started!")

func pause_game():
	game_active = false
	if play_button:
		play_button.text = "Start"
	if game_timer:
		game_timer.stop()

	# Disable all buttons
	for button in number_buttons:
		button.disabled = true

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

func _on_number_pressed(value: int, button: Button):
	if not game_active:
		return

	print("Clicked ", value, ", expecting ", current_count)

	if value == current_count:
		# Correct
		correct_clicks += 1
		consecutive_correct += 1
		total_questions += 1

		print("Correct! Progress: ", current_count, "/", target_number)

		if correct_sound:
			correct_sound.play()

		# Visual feedback
		button.modulate = Color.GREEN
		button.disabled = true
		current_count += 1

		# Check if level complete
		if current_count > target_number:
			print("Level ", current_level, " complete!")
			level_complete()
	else:
		# Incorrect
		incorrect_clicks += 1
		consecutive_correct = 0
		total_questions += 1

		print("Incorrect! Try again.")

		if incorrect_sound:
			incorrect_sound.play()

		# Visual feedback
		var original_color = button.modulate
		button.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(button, "modulate", original_color, 0.5).set_delay(0.3)

func level_complete():
	game_active = false
	if game_timer:
		game_timer.stop()

	# Disable all buttons
	for button in number_buttons:
		button.disabled = true

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

func show_level_complete_popup():
	popup_instance = CompletionPopup.instantiate()
	add_child(popup_instance)

	var settings = difficulty_settings[current_grade]
	var has_next = current_level < settings["max_level"]

	popup_instance.show_level_complete(current_level, target_number, target_number, elapsed_time, has_next)
	popup_instance.level_select_pressed.connect(_on_popup_level_select)
	popup_instance.main_menu_pressed.connect(_on_popup_main_menu)
	popup_instance.next_level_pressed.connect(_on_popup_next_level)

func show_game_complete_popup():
	popup_instance = CompletionPopup.instantiate()
	add_child(popup_instance)

	popup_instance.show_game_complete(correct_clicks, total_questions, elapsed_time)
	popup_instance.level_select_pressed.connect(_on_popup_level_select)
	popup_instance.main_menu_pressed.connect(_on_popup_main_menu)

func _on_popup_level_select():
	save_incomplete_progress()
	if GameData:
		GameData.current_game_settings["selected_game"] = 3
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
	current_count = 1
	setup_new_level()
	start_game()

func _on_levels_button_pressed():
	print("Levels button pressed")

	if game_active:
		pause_game()

	save_incomplete_progress()
	if GameData:
		GameData.current_game_settings["selected_game"] = 3
	get_tree().change_scene_to_file("res://Scenes/LevelSelect/Scenes/level_select.tscn")

func _on_menu_button_pressed():
	print("Menu button pressed")

	if game_active:
		pause_game()

	save_incomplete_progress()
	get_tree().change_scene_to_file("res://Scenes/MainMenu/Scene/MainMenu.tscn")

func save_incomplete_progress():
	if GameData and total_questions > 0:
		var accuracy = (float(correct_clicks) / float(total_questions) * 100.0) if total_questions > 0 else 0
		var result = {
			"game_name": "Counting Game",
			"grade_level": current_grade,
			"time": elapsed_time,
			"correct": correct_clicks,
			"incorrect": incorrect_clicks,
			"total": total_questions,
			"levels_completed": current_level - 1,
			"accuracy": accuracy
		}
		GameData.save_game_result(result)
		print("Progress saved")

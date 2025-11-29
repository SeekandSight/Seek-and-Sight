extends Node2D

var game_active = false
var elapsed_time = 0
var correct_matches = 0
var incorrect_matches = 0
var current_level = 1
var consecutive_correct = 0
var total_matches_needed = 0
var last_level_numbers = []

var difficulty_settings = {
	"Kindergarten": {
		"max_level": 15,
		"questions_per_level": 5
	},
	"1st Grade": {
		"max_level": 20,
		"questions_per_level": 7
	},
	"2nd Grade": {
		"max_level": 25,
		"questions_per_level": 10
	}
}

var number_words = {
	0: "zero", 1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
	6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
	11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen",
	16: "sixteen", 17: "seventeen", 18: "eighteen", 19: "nineteen", 20: "twenty",
	21: "twenty-one", 22: "twenty-two", 23: "twenty-three", 24: "twenty-four",
	25: "twenty-five", 26: "twenty-six", 27: "twenty-seven", 28: "twenty-eight",
	29: "twenty-nine", 30: "thirty", 31: "thirty-one", 32: "thirty-two",
	33: "thirty-three", 34: "thirty-four", 35: "thirty-five", 36: "thirty-six",
	37: "thirty-seven", 38: "thirty-eight", 39: "thirty-nine", 40: "forty",
	41: "forty-one", 42: "forty-two", 43: "forty-three", 44: "forty-four",
	45: "forty-five", 46: "forty-six", 47: "forty-seven", 48: "forty-eight",
	49: "forty-nine", 50: "fifty", 60: "sixty", 70: "seventy", 80: "eighty",
	90: "ninety", 100: "one hundred"
}

var current_grade = "Kindergarten"
var current_numbers = []
var current_words = []
var questions_this_level = 0
var total_questions = 0

@onready var numbers_container = get_node_or_null("UI/DragArea/NumbersContainer")
@onready var words_container = get_node_or_null("UI/DropArea/WordsContainer")
@onready var timer_label = get_node_or_null("UI/ControlPanel/TimerLabel")
@onready var play_button = get_node_or_null("UI/ControlPanel/PlayButton")
@onready var menu_button = get_node_or_null("UI/ControlPanel/MenuButton")
@onready var levels_button = get_node_or_null("UI/ControlPanel/LevelsButton")
@onready var level_label = get_node_or_null("UI/GoalArea/LevelLabel")
@onready var score_label = get_node_or_null("UI/GoalArea/ScoreLabel")
@onready var game_timer = get_node_or_null("GameTimer")
@onready var correct_sound = get_node_or_null("CorrectSound")
@onready var incorrect_sound = get_node_or_null("IncorrectSound")

var DraggableNumber = preload("res://Scenes/Minigame 1/Scene/draggable_number.tscn")
var DropZone = preload("res://Scenes/Minigame 1/Scene/drop_zone.tscn")
var CompletionPopup = preload("res://Scenes/UI/completion_popup.tscn")

var popup_instance = null

func _ready():
	print("=== Number Match Game Starting ===")
	
	if GameData and GameData.current_game_settings.has("selected_level"):
		current_level = GameData.current_game_settings["selected_level"]
		print("Starting at selected level: ", current_level)
		GameData.current_game_settings.erase("selected_level")
	
	if not numbers_container or not words_container or not play_button or not menu_button or not game_timer:
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

func number_to_word(num: int) -> String:
	if num in number_words:
		return number_words[num]
	
	if num > 50 and num < 100:
		var tens = (num / 10) * 10
		var ones = num % 10
		if ones == 0:
			return number_words.get(tens, str(num))
		else:
			var tens_word = number_words.get(tens, "")
			var ones_word = number_words.get(ones, "")
			if tens_word and ones_word:
				return tens_word + "-" + ones_word
	
	return str(num)

func get_level_number_range(level: int) -> Dictionary:
	var range_start = 1
	var range_end = 10
	
	if level <= 3:
		range_start = 1
		range_end = 10
	elif level <= 6:
		range_start = 5
		range_end = 30
	elif level <= 9:
		range_start = 1
		range_end = 50
	elif level <= 12:
		range_start = 20
		range_end = 70
	else:
		range_start = 1
		range_end = 100
	
	return {"start": range_start, "end": range_end}

func setup_new_level():
	if not numbers_container or not words_container:
		push_error("Cannot setup level: containers missing")
		return
	
	print("\n=== Setting up Level ", current_level, " ===")
	
	disable_all_draggables()
	clear_container(numbers_container)
	clear_container(words_container)
	
	var settings = difficulty_settings[current_grade]
	var num_questions = settings["questions_per_level"]
	
	var range_dict = get_level_number_range(current_level)
	var range_start = range_dict["start"]
	var range_end = range_dict["end"]
	
	print("Level ", current_level, " range: ", range_start, " to ", range_end)
	
	current_numbers = generate_engaging_numbers(range_start, range_end, num_questions)
	print("Generated numbers: ", current_numbers)
	
	last_level_numbers = current_numbers.duplicate()
	
	current_words = []
	for num in current_numbers:
		var word = number_to_word(num)
		current_words.append(word)
		print("  ", num, " -> '", word, "'")
	
	var shuffled_words = current_words.duplicate()
	shuffled_words.shuffle()
	print("Shuffled words: ", shuffled_words)
	
	for i in range(current_numbers.size()):
		var num = current_numbers[i]
		var word = number_to_word(num)
		
		var draggable = DraggableNumber.instantiate()
		numbers_container.add_child(draggable)
		await get_tree().process_frame
		
		draggable.set_number(num, word)
		draggable.match_made.connect(_on_match_made)
		draggable.number_removed.connect(_on_number_removed)
		draggable.disable_dragging()
	
	for i in range(shuffled_words.size()):
		var word = shuffled_words[i]
		
		var drop_zone = DropZone.instantiate()
		words_container.add_child(drop_zone)
		await get_tree().process_frame
		
		drop_zone.set_word(word)
	
	questions_this_level = 0
	total_matches_needed = num_questions
	update_level_display()
	
	await get_tree().process_frame
	if game_active:
		print("Re-enabling dragging after level setup")
		enable_all_draggables()
	
	print("=== Level setup complete - Need ", total_matches_needed, " correct matches ===\n")

func generate_engaging_numbers(range_start: int, range_end: int, count: int) -> Array:
	var available = []
	
	for i in range(range_start, range_end + 1):
		if not i in last_level_numbers:
			available.append(i)
	
	if available.size() < count:
		for i in range(range_start, range_end + 1):
			if not i in available:
				available.append(i)
	
	available.shuffle()
	
	var selected = []
	var easy_count = 0
	var hard_count = 0
	
	for num in available:
		if selected.size() >= count:
			break
		
		var is_easy = (num <= 10)
		var is_hard = (num > 20)
		
		if is_easy and easy_count < count / 2:
			selected.append(num)
			easy_count += 1
		elif is_hard and hard_count < count / 2:
			selected.append(num)
			hard_count += 1
		elif selected.size() < count:
			selected.append(num)
	
	selected.sort()
	
	return selected

func clear_container(container):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func enable_all_draggables():
	if numbers_container:
		await get_tree().process_frame
		for child in numbers_container.get_children():
			if child.has_method("enable_dragging"):
				child.enable_dragging()
		print("All draggables enabled")

func disable_all_draggables():
	if numbers_container:
		for child in numbers_container.get_children():
			if child.has_method("disable_dragging"):
				child.disable_dragging()

func _on_number_removed():
	print("Number removed, updating remaining positions...")
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	if numbers_container:
		for child in numbers_container.get_children():
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
	get_tree().change_scene_to_file("res://Scenes/LevelSelect/Scene/level_select.tscn")

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
			"game_name": "Number Match",
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

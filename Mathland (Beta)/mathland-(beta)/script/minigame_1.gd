# minigame_1.gd - Simple Math Number Matching Game
extends Control

# Game configuration
var difficulty_levels = {
	"easy": {"range": 5, "count": 4, "rounds": 3},      # 1-5, show 4 at a time, 3 rounds
	"medium": {"range": 10, "count": 4, "rounds": 4},   # 1-10, show 4 at a time, 4 rounds
	"hard": {"range": 20, "count": 4, "rounds": 5}      # 1-20, show 4 at a time, 5 rounds
}
var current_difficulty = "easy"

# Game tracking
var current_round = 0
var total_rounds = 3
var total_matches = 0
var matches_remaining = 4
var is_game_active = false
var is_game_started = false
var correct_matches_this_round = 0

# Current round data
var current_numbers = []
var current_number_words = []
var number_words_dict = {
	1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
	6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
	11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen",
	16: "sixteen", 17: "seventeen", 18: "eighteen", 19: "nineteen", 20: "twenty"
}

# Dynamic bubbles
var active_number_bubbles = []
var active_word_bubbles = []

# UI node references
@onready var timer_label = $UI/TimerContainer/TimerLabel
@onready var score_label = $UI/ScoreContainer/ScoreLabel
@onready var rounds_label = $UI/RoundsContainer/RoundsLabel
@onready var feedback_label = $UI/FeedbackLabel

# Difficulty selection popup
@onready var difficulty_popup = $UI/DifficultyPopup
@onready var easy_btn = $UI/DifficultyPopup/VBoxContainer/EasyButton
@onready var medium_btn = $UI/DifficultyPopup/VBoxContainer/MediumButton
@onready var hard_btn = $UI/DifficultyPopup/VBoxContainer/HardButton

# Game completion popup
@onready var round_complete_popup = $UI/RoundCompletePopup
@onready var results_label = $UI/RoundCompletePopup/ResultsLabel
@onready var next_round_button = $UI/RoundCompletePopup/ButtonContainer/NextRoundButton
@onready var finish_button = $UI/RoundCompletePopup/ButtonContainer/FinishButton

# Game area references
@onready var card_container = $GameContainer/HBoxContainer/LeftColumn/NumbersBubble/CardContainer
@onready var target_container = $GameContainer/HBoxContainer/RightColumn/AnswerBubble/TargetContainer

# Control buttons
@onready var start_button = $ControlsContainer/StartButton
@onready var reset_button = $ControlsContainer/ResetButton
@onready var options_button = $ControlsContainer/OptionsButton
@onready var back_button = $ControlsContainer/BackButton

# Audio references
@onready var success_sound = $Audio/SuccessSound
@onready var error_sound = $Audio/ErrorSound
@onready var background_music = $Audio/BackgroundMusic

# Game timer
var start_time = 0.0

func _ready():
	"""Initialize the game"""
	print("🧙‍♂️ Math Wizard Starting...")
	await get_tree().process_frame
	
	setup_ui()
	connect_signals()
	print("✅ Game ready!")

func setup_ui():
	"""Initialize UI elements"""
	timer_label.text = "Time: 00:00"
	score_label.text = "Score: 0/4"
	update_rounds_display()
	feedback_label.text = ""
	
	if difficulty_popup:
		difficulty_popup.hide()
	
	if round_complete_popup:
		round_complete_popup.hide()
	
	if reset_button:
		reset_button.disabled = true

func update_rounds_display():
	"""Update the rounds label based on current difficulty"""
	var total = difficulty_levels[current_difficulty]["rounds"]
	rounds_label.text = "Round: %d/%d" % [current_round, total]

func connect_signals():
	"""Connect button signals"""
	if start_button:
		start_button.pressed.connect(_on_start_game)
	if reset_button:
		reset_button.pressed.connect(_on_reset_game)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_to_menu)
	
	# Difficulty selection buttons
	if easy_btn:
		easy_btn.pressed.connect(_on_difficulty_selected.bind("easy"))
	if medium_btn:
		medium_btn.pressed.connect(_on_difficulty_selected.bind("medium"))
	if hard_btn:
		hard_btn.pressed.connect(_on_difficulty_selected.bind("hard"))
	
	# Round complete popup buttons
	if next_round_button:
		next_round_button.pressed.connect(_on_next_round_pressed)
	if finish_button:
		finish_button.pressed.connect(_on_finish_game_pressed)

func _on_start_game():
	"""Start or continue the game"""
	if not is_game_started:
		# Start new game
		print("🎯 Starting new game on %s difficulty..." % current_difficulty)
		current_round = 0
		total_matches = 0
		total_rounds = difficulty_levels[current_difficulty]["rounds"]
		start_time = Time.get_unix_time_from_system()
		is_game_started = true
		
		if start_button:
			start_button.text = "Next Round"
		if reset_button:
			reset_button.disabled = false
		
		start_new_round()
	else:
		# Next round
		if current_round < total_rounds:
			start_new_round()
		else:
			# Game completed
			complete_game()

func start_new_round():
	"""Start a new round"""
	current_round += 1
	correct_matches_this_round = 0
	matches_remaining = 4
	is_game_active = true
	
	print("🎮 Starting Round %d/%d on %s difficulty" % [current_round, total_rounds, current_difficulty])
	
	# Update UI
	update_rounds_display()
	score_label.text = "Score: 0/4"
	
	# Generate and create bubbles
	generate_round_numbers()
	clear_dynamic_bubbles()
	await get_tree().process_frame
	create_dynamic_number_bubbles()
	create_dynamic_word_bubbles()
	
	show_feedback("Round %d - Match the numbers! 🎯" % current_round, Color.BLUE)
	
	# Disable start button during round
	if start_button:
		start_button.disabled = true

func generate_round_numbers():
	"""Generate 4 random numbers for this round based on current difficulty"""
	var level_config = difficulty_levels[current_difficulty]
	var max_range = level_config["range"]
	var count = level_config["count"]
	
	current_numbers = []
	current_number_words = []
	
	print("🎲 Generating numbers from 1 to %d for %s difficulty" % [max_range, current_difficulty])
	
	# Generate random unique numbers within the difficulty range
	var available_numbers = []
	for i in range(1, max_range + 1):
		available_numbers.append(i)
	
	available_numbers.shuffle()
	for i in range(count):
		var number = available_numbers[i]
		current_numbers.append(number)
		current_number_words.append(number_words_dict[number])
	
	print("🎲 Numbers: %s | Words: %s" % [str(current_numbers), str(current_number_words)])

func clear_dynamic_bubbles():
	"""Clear all bubbles"""
	for bubble in active_number_bubbles:
		if bubble and is_instance_valid(bubble):
			bubble.queue_free()
	for bubble in active_word_bubbles:
		if bubble and is_instance_valid(bubble):
			bubble.queue_free()
	
	active_number_bubbles.clear()
	active_word_bubbles.clear()
	await get_tree().process_frame

func create_dynamic_number_bubbles():
	"""Create number bubbles"""
	if not card_container:
		return
	
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.ORANGE]
	var bubble_size = 80
	
	for i in range(current_numbers.size()):
		var number = current_numbers[i]
		var color = colors[i % colors.size()]
		var bubble = create_circular_number_bubble(number, color, bubble_size)
		
		# Position with anchors
		bubble.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bubble.anchor_left = 0.5
		bubble.anchor_right = 0.5
		
		var y_offset = 60 + (i * 100)
		bubble.offset_left = -bubble_size / 2
		bubble.offset_right = bubble_size / 2
		bubble.offset_top = y_offset
		bubble.offset_bottom = y_offset + bubble_size
		bubble.set_meta("original_offset_top", y_offset)
		
		card_container.add_child(bubble)
		active_number_bubbles.append(bubble)

func create_dynamic_word_bubbles():
	"""Create word bubbles"""
	if not target_container:
		return
	
	var colors = [Color.LIGHT_CORAL, Color.LIGHT_BLUE, Color.LIGHT_GREEN, Color.LIGHT_GOLDENROD]
	var bubble_height = 70
	var bubble_width = 200
	
	# Shuffle word positions for challenge
	var shuffled_indices = []
	for i in range(current_number_words.size()):
		shuffled_indices.append(i)
	shuffled_indices.shuffle()
	
	for i in range(current_number_words.size()):
		var word_index = shuffled_indices[i]
		var word = current_number_words[word_index]
		var matching_number = current_numbers[word_index]
		var color = colors[i % colors.size()]
		
		var bubble = create_rectangular_word_bubble(matching_number, word, color)
		
		# Position with anchors
		bubble.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bubble.anchor_left = 0.5
		bubble.anchor_right = 0.5
		
		var y_offset = 60 + (i * 90)
		bubble.offset_left = -bubble_width / 2
		bubble.offset_right = bubble_width / 2
		bubble.offset_top = y_offset
		bubble.offset_bottom = y_offset + bubble_height
		
		target_container.add_child(bubble)
		active_word_bubbles.append(bubble)

func create_circular_number_bubble(number: int, color: Color, size: float = 80.0) -> Control:
	"""Create a number bubble"""
	var card = Control.new()
	card.custom_minimum_size = Vector2(size, size)
	card.size = Vector2(size, size)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Background
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	var radius = size / 2
	style_box.corner_radius_top_left = radius
	style_box.corner_radius_top_right = radius
	style_box.corner_radius_bottom_left = radius
	style_box.corner_radius_bottom_right = radius
	style_box.border_width_left = 4
	style_box.border_width_right = 4
	style_box.border_width_top = 4
	style_box.border_width_bottom = 4
	style_box.border_color = Color.WHITE
	
	bg.add_theme_stylebox_override("panel", style_box)
	card.add_child(bg)
	
	# Number label
	var label = Label.new()
	label.text = str(number)
	label.add_theme_font_size_override("font_size", int(size * 0.45))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.z_index = 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	
	# Set metadata
	card.set_meta("number", number)
	card.set_meta("is_dragging", false)
	
	# Connect signals
	card.gui_input.connect(_on_number_bubble_input.bind(card))
	card.mouse_entered.connect(func(): 
		if not card.get_meta("is_dragging", false):
			card.scale = Vector2(1.05, 1.05)
	)
	card.mouse_exited.connect(func(): 
		if not card.get_meta("is_dragging", false):
			card.scale = Vector2.ONE
	)
	
	return card

func create_rectangular_word_bubble(number: int, word: String, color: Color) -> Control:
	"""Create a word bubble"""
	var target = Control.new()
	target.custom_minimum_size = Vector2(200, 70)
	target.size = Vector2(200, 70)
	
	# Background
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.corner_radius_top_left = 35
	style_box.corner_radius_top_right = 35
	style_box.corner_radius_bottom_left = 35
	style_box.corner_radius_bottom_right = 35
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color.DARK_GRAY
	
	bg.add_theme_stylebox_override("panel", style_box)
	target.add_child(bg)
	
	# Word label
	var label = Label.new()
	label.text = word.capitalize()
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.z_index = 2
	target.add_child(label)
	
	# Store data
	target.set_meta("target_number", number)
	target.set_meta("word", word)
	target.set_meta("is_filled", false)
	
	return target

func _process(delta):
	"""Update timer"""
	if is_game_active and is_game_started and timer_label:
		var elapsed_time = Time.get_unix_time_from_system() - start_time
		var minutes = int(elapsed_time) / 60
		var seconds = int(elapsed_time) % 60
		timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _on_number_bubble_input(event: InputEvent, bubble: Control):
	"""Handle bubble dragging"""
	if not is_game_active:
		return
		
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				start_bubble_drag(bubble, mouse_event.position)
			else:
				end_bubble_drag(bubble)
	elif event is InputEventMouseMotion:
		if bubble.get_meta("is_dragging", false):
			update_bubble_drag(bubble, event.position)

func start_bubble_drag(bubble: Control, mouse_pos: Vector2):
	"""Start dragging"""
	bubble.set_meta("is_dragging", true)
	bubble.set_meta("drag_offset", mouse_pos)
	bubble.z_index = 100
	bubble.scale = Vector2(1.1, 1.1)

func update_bubble_drag(bubble: Control, mouse_pos: Vector2):
	"""Update drag position"""
	var drag_offset = bubble.get_meta("drag_offset")
	bubble.global_position = get_global_mouse_position() - drag_offset

func end_bubble_drag(bubble: Control):
	"""End dragging and check for matches"""
	if not bubble.get_meta("is_dragging", false):
		return
	
	bubble.set_meta("is_dragging", false)
	bubble.z_index = 0
	bubble.scale = Vector2.ONE
	
	var target = find_drop_target(bubble)
	if target:
		attempt_drop(bubble, target)
	else:
		return_bubble_to_original_position(bubble)

func find_drop_target(bubble: Control) -> Control:
	"""Find target under bubble"""
	var bubble_center = bubble.global_position + bubble.size / 2
	
	for target in active_word_bubbles:
		if target and is_instance_valid(target) and not target.get_meta("is_filled", false):
			var target_rect = Rect2(target.global_position, target.size)
			if target_rect.has_point(bubble_center):
				return target
	
	return null

func attempt_drop(bubble: Control, target: Control):
	"""Check if drop is correct"""
	var bubble_number = bubble.get_meta("number")
	var target_number = target.get_meta("target_number")
	var target_word = target.get_meta("word")
	
	if bubble_number == target_number:
		# Correct match
		snap_bubble_to_target(bubble, target)
		target.set_meta("is_filled", true)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animate_success_target(target)
		handle_correct_match()
	else:
		# Wrong match
		return_bubble_to_original_position(bubble)
		handle_incorrect_match()

func snap_bubble_to_target(bubble: Control, target: Control):
	"""Move bubble to target"""
	var target_pos = target.global_position + Vector2(20, 5)
	var tween = create_tween()
	tween.tween_property(bubble, "global_position", target_pos, 0.3)

func return_bubble_to_original_position(bubble: Control):
	"""Return bubble to original position"""
	# Reset bubble properties
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	bubble.set_meta("is_dragging", false)
	bubble.z_index = 0
	bubble.scale = Vector2.ONE
	
	# Return to original position
	var original_offset_top = bubble.get_meta("original_offset_top", 60)
	var tween = create_tween()
	tween.tween_property(bubble, "offset_top", original_offset_top, 0.3)
	tween.tween_property(bubble, "offset_bottom", original_offset_top + 80, 0.3)
	
	# Reset position properties
	tween.tween_callback(func():
		bubble.offset_left = -40
		bubble.offset_right = 40
	)

func animate_success_target(target: Control):
	"""Animate successful match"""
	target.self_modulate = Color.LIGHT_GREEN
	var tween = create_tween()
	tween.tween_property(target, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(target, "scale", Vector2.ONE, 0.2)

func handle_correct_match():
	"""Handle correct match"""
	correct_matches_this_round += 1
	total_matches += 1
	matches_remaining -= 1
	
	if success_sound:
		success_sound.play()
	
	var messages = ["Excellent! ⭐", "Great job! 🌟", "Perfect! 🎯", "Amazing! ✨"]
	show_feedback(messages[randi() % messages.size()], Color.GREEN)
	
	score_label.text = "Score: %d/4" % correct_matches_this_round
	
	# Check if round complete
	if matches_remaining <= 0:
		complete_round()

func handle_incorrect_match():
	"""Handle wrong match"""
	if error_sound:
		error_sound.play()
	
	var messages = ["Try again! 🤔", "Almost! Keep going! 💪", "You've got this! 🎈", "Don't give up! 🌟"]
	show_feedback(messages[randi() % messages.size()], Color.ORANGE, 2.0)  # Show for 2 seconds

func complete_round():
	"""Complete current round"""
	is_game_active = false
	
	if current_round < total_rounds:
		# More rounds to go
		show_feedback("Round %d Complete! 🎉" % current_round, Color.GOLD)
		await get_tree().create_timer(2.0).timeout
		
		if start_button:
			start_button.disabled = false
			start_button.text = "Next Round"
	else:
		# All rounds complete
		complete_game()

func complete_game():
	"""Complete current difficulty level"""
	is_game_active = false
	show_feedback("🏆 %s Mode Complete! 🏆" % current_difficulty.capitalize(), Color.GOLD)
	
	await get_tree().create_timer(2.0).timeout
	
	# Show completion popup with options
	show_completion_popup()

func show_completion_popup():
	"""Show completion popup with next difficulty or play again options"""
	if not round_complete_popup or not results_label:
		return
	
	var completion_text = ""
	var elapsed_time = Time.get_unix_time_from_system() - start_time
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	
	completion_text += "[center]🎊 [color=gold]%s DIFFICULTY COMPLETE![/color] 🎊[/center]\n\n" % current_difficulty.capitalize()
	completion_text += "[center]⏱️ Total Time: %02d:%02d[/center]\n" % [minutes, seconds]
	completion_text += "[center]🎯 Rounds Completed: %d/%d[/center]\n" % [current_round, total_rounds]
	completion_text += "[center]⭐ Total Matches: %d[/center]\n\n" % total_matches
	
	# Show next difficulty option or completion message
	if current_difficulty == "easy":
		completion_text += "[center][color=cyan]🎯 Ready for Medium difficulty?\n(Numbers 1-10, 4 rounds)[/color][/center]"
		next_round_button.text = "▶️ Play Medium"
		next_round_button.show()
	elif current_difficulty == "medium":
		completion_text += "[center][color=orange]🔥 Ready for Hard difficulty?\n(Numbers 1-20, 5 rounds)[/color][/center]"
		next_round_button.text = "▶️ Play Hard"
		next_round_button.show()
	else:
		completion_text += "[center][color=gold]🌟 CONGRATULATIONS! 🌟\nYou've completed all difficulties![/color][/center]"
		next_round_button.text = "🎮 Play Again"
		next_round_button.show()
	
	results_label.text = completion_text
	finish_button.text = "➡️ Next Game"
	
	# Configure popup to hide OK button and show only our custom buttons
	round_complete_popup.get_ok_button().hide()
	round_complete_popup.show()

func _on_next_round_pressed():
	"""Handle next difficulty or play again button press"""
	round_complete_popup.hide()
	
	if current_difficulty == "hard":
		# If on hard difficulty, "Play Again" means restart from easy
		current_difficulty = "easy"
		is_game_started = false
		current_round = 0
		total_matches = 0
		total_rounds = difficulty_levels[current_difficulty]["rounds"]
		
		# Update UI
		update_rounds_display()
		if start_button:
			start_button.text = "🎮 Start Easy"
			start_button.disabled = false
		
		show_feedback("🎮 Let's play again from Easy mode!", Color.GREEN, 3.0)
	else:
		# Advance to next difficulty
		if current_difficulty == "easy":
			current_difficulty = "medium"
		elif current_difficulty == "medium":
			current_difficulty = "hard"
		
		# Reset game state for new difficulty
		is_game_started = false
		current_round = 0
		total_matches = 0
		total_rounds = difficulty_levels[current_difficulty]["rounds"]
		
		# Update UI
		update_rounds_display()
		if start_button:
			start_button.text = "🎮 Start %s" % current_difficulty.capitalize()
			start_button.disabled = false
		
		show_feedback("🎯 %s Mode Selected! Ready to start?" % current_difficulty.capitalize(), Color.CYAN, 3.0)

func _on_finish_game_pressed():
	"""Handle next game button press"""
	round_complete_popup.hide()
	# Navigate to next minigame instead of main menu
	get_tree().change_scene_to_file("res://Scenes/2 Minigame2.tscn")

func reset_game():
	"""Reset everything"""
	current_difficulty = "easy"
	is_game_started = false
	is_game_active = false
	current_round = 0
	total_matches = 0
	clear_dynamic_bubbles()
	
	if start_button:
		start_button.text = "🎮 Start Game"
		start_button.disabled = false
	if reset_button:
		reset_button.disabled = true
	
	if round_complete_popup:
		round_complete_popup.hide()
	
	timer_label.text = "Time: 00:00"
	score_label.text = "Score: 0/4"
	update_rounds_display()
	feedback_label.text = ""

func show_feedback(message: String, color: Color, duration: float = 4.0):
	"""Show feedback message with custom duration"""
	if not feedback_label:
		return
	
	feedback_label.text = message
	feedback_label.modulate = color
	
	var tween = create_tween()
	tween.tween_property(feedback_label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.15)
	
	await get_tree().create_timer(duration).timeout
	if feedback_label:
		feedback_label.text = ""

func _on_reset_game():
	"""Reset button pressed"""
	reset_game()

func _on_options_pressed():
	"""Show difficulty options"""
	if difficulty_popup:
		difficulty_popup.show()

func _on_difficulty_selected(difficulty: String):
	"""Select difficulty and reset game"""
	print("🎯 Difficulty selected: %s" % difficulty)
	current_difficulty = difficulty
	
	if difficulty_popup:
		difficulty_popup.hide()
	
	var messages = {
		"easy": "😊 Easy Mode! Numbers 1-5, 3 rounds",
		"medium": "🎯 Medium Mode! Numbers 1-10, 4 rounds", 
		"hard": "🔥 Hard Mode! Numbers 1-20, 5 rounds"
	}
	
	show_feedback(messages[difficulty], Color.YELLOW, 4.0)  # Show for 4 seconds
	
	# Reset game state for selected difficulty
	is_game_started = false
	is_game_active = false
	current_round = 0
	total_matches = 0
	total_rounds = difficulty_levels[current_difficulty]["rounds"]
	
	# Clear any existing bubbles
	clear_dynamic_bubbles()
	
	# Update UI for new difficulty
	update_rounds_display()
	timer_label.text = "Time: 00:00"
	score_label.text = "Score: 0/4"
	feedback_label.text = ""
	
	if start_button:
		start_button.text = "🎮 Start %s" % difficulty.capitalize()
		start_button.disabled = false
	if reset_button:
		reset_button.disabled = true

func _on_back_to_menu():
	"""Return to menu"""
	get_tree().change_scene_to_file("res://Scenes/1 MainMenu.tscn")

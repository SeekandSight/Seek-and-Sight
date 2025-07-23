# minigame_1.gd - Optimized Math Number Matching Game
extends Control

# Game configuration
var difficulty_levels = {
	"easy": {"range": 5, "count": 4, "rounds": 3},
	"medium": {"range": 10, "count": 4, "rounds": 4},
	"hard": {"range": 20, "count": 4, "rounds": 5}
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

# Scaling variables
var base_bubble_size = 60
var base_word_bubble_width = 160
var base_word_bubble_height = 50
var scale_factor = 1.0

# UI node references
@onready var timer_label = $UI/TimerContainer/TimerLabel
@onready var score_label = $UI/ScoreContainer/ScoreLabel
@onready var rounds_label = $UI/RoundsContainer/RoundsLabel
@onready var feedback_label = $UI/FeedbackLabel

# Popups
@onready var difficulty_popup = $UI/DifficultyPopup
@onready var easy_btn = $UI/DifficultyPopup/VBoxContainer/EasyButton
@onready var medium_btn = $UI/DifficultyPopup/VBoxContainer/MediumButton
@onready var hard_btn = $UI/DifficultyPopup/VBoxContainer/HardButton

@onready var round_complete_popup = $UI/RoundCompletePopup
@onready var results_label = $UI/RoundCompletePopup/ResultsLabel
@onready var next_round_button = $UI/RoundCompletePopup/ButtonContainer/NextRoundButton
@onready var finish_button = $UI/RoundCompletePopup/ButtonContainer/FinishButton

# Game containers
@onready var card_container = $GameContainer/HBoxContainer/LeftColumn/NumbersBubble/CardContainer
@onready var target_container = $GameContainer/HBoxContainer/RightColumn/AnswerBubble/TargetContainer

# Control buttons
@onready var start_button = $ControlsContainer/StartButton
@onready var reset_button = $ControlsContainer/ResetButton
@onready var options_button = $ControlsContainer/OptionsButton
@onready var back_button = $ControlsContainer/BackButton

# Audio
@onready var success_sound = $Audio/SuccessSound
@onready var error_sound = $Audio/ErrorSound
@onready var background_music = $Audio/BackgroundMusic

# Game timer
var start_time = 0.0

func _ready():
	"""Initialize the game"""
	await get_tree().process_frame
	calculate_scale_factor()
	setup_ui()
	setup_responsive_ui()
	connect_signals()

func calculate_scale_factor():
	"""Calculate scale factor based on screen size"""
	var viewport_size = get_viewport().get_visible_rect().size
	var base_width = 1152
	var base_height = 648
	
	var width_scale = viewport_size.x / base_width
	var height_scale = viewport_size.y / base_height
	scale_factor = min(width_scale, height_scale)
	
	# More conservative scaling for full screen to maintain layout proportions
	if viewport_size.x >= 1400 or viewport_size.y >= 900:
		scale_factor = clamp(scale_factor * 0.8, 0.7, 1.2)  # More conservative
	elif viewport_size.x <= 800 or viewport_size.y <= 600:
		scale_factor = clamp(scale_factor * 1.1, 0.6, 1.0)
	else:
		scale_factor = clamp(scale_factor, 0.7, 1.2)

func setup_responsive_ui():
	"""Setup responsive UI scaling"""
	var ui_scale = scale_factor
	var viewport_size = get_viewport().get_visible_rect().size
	var is_fullscreen = viewport_size.x >= 1400 or viewport_size.y >= 900
	var is_small_screen = viewport_size.x <= 800
	
	# Scale UI containers
	if timer_label:
		timer_label.get_parent().scale = Vector2(ui_scale, ui_scale)
	if score_label:
		score_label.get_parent().scale = Vector2(ui_scale, ui_scale)
	if rounds_label:
		rounds_label.get_parent().scale = Vector2(ui_scale, ui_scale)
	
	# Adjust layout for full-screen mode
	var character_area = $CharacterArea
	var controls_container = $ControlsContainer
	var game_container = $GameContainer
	
	if is_fullscreen:
		# Keep the same proportional layout as windowed mode
		if character_area:
			# Keep title in the same relative position
			character_area.offset_left = -400
			character_area.offset_top = -320  # Slightly higher to maintain proportion
			character_area.offset_right = 400
			character_area.offset_bottom = -170
		
		if controls_container:
			# Keep controls in the same relative position
			controls_container.offset_left = -400
			controls_container.offset_top = -120
			controls_container.offset_right = 400
			controls_container.offset_bottom = -60
		
		if game_container:
			# Maintain the same proportional margins as windowed mode
			var margin_x = viewport_size.x * 0.04  # 4% margin like windowed mode
			var top_offset = 180  # Keep same offset as windowed
			var bottom_offset = 100  # Keep same offset as windowed
			
			game_container.offset_left = margin_x
			game_container.offset_right = -margin_x
			game_container.offset_top = top_offset
			game_container.offset_bottom = -bottom_offset
	
	elif is_small_screen:
		# Small screen adjustments
		if character_area:
			character_area.offset_left = -300
			character_area.offset_top = -50
			character_area.offset_right = 300
			character_area.offset_bottom = -180
		
		if controls_container:
			controls_container.offset_left = -300
			controls_container.offset_top = -80
			controls_container.offset_right = 300
			controls_container.offset_bottom = -20
		
		if game_container:
			game_container.offset_left = 20
			game_container.offset_right = -20
			game_container.offset_top = 160
			game_container.offset_bottom = -80
	
	# Update font sizes
	var button_font_size = int(clamp(24 * ui_scale, 16, 32))
	var instruction_font_size = int(clamp(28 * ui_scale, 20, 40))
	var title_font_size = int(clamp(60 * ui_scale, 30, 80))
	
	# Adjust font sizes for full screen to prevent oversized text
	if is_fullscreen:
		button_font_size = int(clamp(20 * ui_scale, 16, 28))
		instruction_font_size = int(clamp(24 * ui_scale, 18, 32))
		title_font_size = int(clamp(48 * ui_scale, 30, 60))
	
	if start_button:
		start_button.add_theme_font_size_override("font_size", button_font_size)
	if options_button:
		options_button.add_theme_font_size_override("font_size", int(button_font_size * 0.8))
	if reset_button:
		reset_button.add_theme_font_size_override("font_size", int(button_font_size * 0.8))
	if back_button:
		back_button.add_theme_font_size_override("font_size", int(button_font_size * 0.9))
	
	# Update instruction labels
	var instruction_labels = [
		$GameContainer/HBoxContainer/LeftColumn/InstructionsLabel,
		$GameContainer/HBoxContainer/RightColumn/AnswerInstructions
	]
	for label in instruction_labels:
		if label:
			label.add_theme_font_size_override("font_size", instruction_font_size)
	
	# Update bubble labels
	var bubble_labels = [
		$GameContainer/HBoxContainer/LeftColumn/NumbersBubble/NumbersBubbleLabel,
		$GameContainer/HBoxContainer/RightColumn/AnswerBubble/AnswerBubbleLabel
	]
	var bubble_label_font_size = int(clamp(20 * ui_scale, 16, 28))
	if is_fullscreen:
		bubble_label_font_size = int(clamp(18 * ui_scale, 14, 24))
	for label in bubble_labels:
		if label:
			label.add_theme_font_size_override("font_size", bubble_label_font_size)
	
	# Update game title
	var game_title = $CharacterArea/EllieBubble/GameTitle
	if game_title:
		game_title.add_theme_font_size_override("font_size", title_font_size)

func setup_ui():
	"""Initialize UI elements"""
	timer_label.text = "Time: 00:00"
	score_label.text = "Score: 0/4"
	update_rounds_display()
	feedback_label.text = ""
	
	difficulty_popup.hide()
	round_complete_popup.hide()
	reset_button.disabled = true

func update_rounds_display():
	"""Update the rounds label"""
	var total = difficulty_levels[current_difficulty]["rounds"]
	rounds_label.text = "Round: %d/%d" % [current_round, total]

func connect_signals():
	"""Connect button signals"""
	start_button.pressed.connect(_on_start_game)
	reset_button.pressed.connect(_on_reset_game)
	options_button.pressed.connect(_on_options_pressed)
	back_button.pressed.connect(_on_back_to_menu)
	
	easy_btn.pressed.connect(_on_difficulty_selected.bind("easy"))
	medium_btn.pressed.connect(_on_difficulty_selected.bind("medium"))
	hard_btn.pressed.connect(_on_difficulty_selected.bind("hard"))
	
	next_round_button.pressed.connect(_on_next_round_pressed)
	finish_button.pressed.connect(_on_finish_game_pressed)

func _on_start_game():
	"""Show difficulty selection instead of starting immediately"""
	difficulty_popup.popup_centered()

func _on_difficulty_selected(difficulty: String):
	"""Select difficulty and automatically start game"""
	current_difficulty = difficulty
	difficulty_popup.hide()
	
	var messages = {
		"easy": "😊 Easy Mode Selected! Numbers 1-5, 3 rounds",
		"medium": "🎯 Medium Mode Selected! Numbers 1-10, 4 rounds", 
		"hard": "🔥 Hard Mode Selected! Numbers 1-20, 5 rounds"
	}
	
	# Show selection message for longer duration
	show_feedback(messages[difficulty], Color.CYAN, 3.0)
	
	# Wait longer before auto-starting to let user read the message
	await get_tree().create_timer(2.5).timeout
	
	# Show starting message
	show_feedback("🎮 Starting game...", Color.GREEN, 1.5)
	await get_tree().create_timer(1.0).timeout
	
	auto_start_game()

func auto_start_game():
	"""Automatically start the game after difficulty selection"""
	current_round = 0
	total_matches = 0
	total_rounds = difficulty_levels[current_difficulty]["rounds"]
	start_time = Time.get_unix_time_from_system()
	is_game_started = true
	start_button.text = "Next Round"
	reset_button.disabled = false
	start_new_round()

func start_new_round():
	"""Start a new round"""
	current_round += 1
	correct_matches_this_round = 0
	var level_config = difficulty_levels[current_difficulty]
	matches_remaining = level_config["count"]
	is_game_active = true
	
	update_rounds_display()
	score_label.text = "Score: 0/%d" % matches_remaining
	
	generate_round_numbers()
	clear_dynamic_bubbles()
	await get_tree().process_frame
	create_dynamic_number_bubbles()
	create_dynamic_word_bubbles()
	
	# Clear any previous feedback before showing round message
	feedback_label.text = ""
	await get_tree().create_timer(0.5).timeout
	
	show_feedback("Round %d - Match the numbers! 🎯" % current_round, Color.BLUE, 3.0)
	start_button.disabled = true

func generate_round_numbers():
	"""Generate random numbers for this round"""
	var level_config = difficulty_levels[current_difficulty]
	var max_range = level_config["range"]
	var count = level_config["count"]
	
	current_numbers = []
	current_number_words = []
	
	var available_numbers = []
	for i in range(1, max_range + 1):
		available_numbers.append(i)
	
	available_numbers.shuffle()
	
	for i in range(count):
		var number = available_numbers[i]
		current_numbers.append(number)
		current_number_words.append(number_words_dict[number])

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
	"""Create number bubbles with proper spacing"""
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.ORANGE]
	var bubble_size = base_bubble_size * scale_factor
	var container_rect = card_container.get_rect()
	var available_height = container_rect.size.y - 20
	var gap = (available_height - (current_numbers.size() * bubble_size)) / (current_numbers.size() + 1)
	
	for i in range(current_numbers.size()):
		var number = current_numbers[i]
		var color = colors[i % colors.size()]
		var bubble = create_circular_number_bubble(number, color, bubble_size)
		
		var y_position = gap + (i * (bubble_size + gap))
		bubble.position = Vector2(
			(container_rect.size.x - bubble_size) / 2,
			y_position
		)
		bubble.set_meta("original_position", bubble.position)
		
		card_container.add_child(bubble)
		active_number_bubbles.append(bubble)

func create_dynamic_word_bubbles():
	"""Create word bubbles with proper spacing"""
	var colors = [Color.LIGHT_CORAL, Color.LIGHT_BLUE, Color.LIGHT_GREEN, Color.LIGHT_GOLDENROD]
	var bubble_height = base_word_bubble_height * scale_factor
	var bubble_width = base_word_bubble_width * scale_factor
	var container_rect = target_container.get_rect()
	var available_height = container_rect.size.y - 20
	var gap = (available_height - (current_number_words.size() * bubble_height)) / (current_number_words.size() + 1)
	
	# Shuffle word positions
	var shuffled_indices = []
	for i in range(current_number_words.size()):
		shuffled_indices.append(i)
	shuffled_indices.shuffle()
	
	for i in range(current_number_words.size()):
		var word_index = shuffled_indices[i]
		var word = current_number_words[word_index]
		var matching_number = current_numbers[word_index]
		var color = colors[i % colors.size()]
		
		var bubble = create_rectangular_word_bubble(matching_number, word, color, bubble_width, bubble_height)
		
		var y_position = gap + (i * (bubble_height + gap))
		bubble.position = Vector2(
			(container_rect.size.x - bubble_width) / 2,
			y_position
		)
		bubble.set_meta("original_position", bubble.position)
		
		target_container.add_child(bubble)
		active_word_bubbles.append(bubble)

func create_circular_number_bubble(number: int, color: Color, size: float) -> Control:
	"""Create a circular number bubble"""
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
	var border_width = max(4 * scale_factor, 2)
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.border_color = Color.WHITE
	
	bg.add_theme_stylebox_override("panel", style_box)
	card.add_child(bg)
	
	# Number label
	var label = Label.new()
	label.text = str(number)
	var font_size = int(size * 0.5)
	label.add_theme_font_size_override("font_size", font_size)
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

func create_rectangular_word_bubble(number: int, word: String, color: Color, width: float, height: float) -> Control:
	"""Create a rectangular word bubble"""
	var target = Control.new()
	target.custom_minimum_size = Vector2(width, height)
	target.size = Vector2(width, height)
	
	# Background
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	var corner_radius = height * 0.5
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius
	var border_width = max(3 * scale_factor, 2)
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.border_color = Color.DARK_GRAY
	
	bg.add_theme_stylebox_override("panel", style_box)
	target.add_child(bg)
	
	# Word label
	var label = Label.new()
	label.text = word.capitalize()
	var font_size = int(height * 0.6)
	font_size = max(font_size, 14)
	label.add_theme_font_size_override("font_size", font_size)
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
	
	if bubble_number == target_number:
		snap_bubble_to_target(bubble, target)
		target.set_meta("is_filled", true)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animate_success_target(target)
		handle_correct_match()
	else:
		return_bubble_to_original_position(bubble)
		handle_incorrect_match()

func snap_bubble_to_target(bubble: Control, target: Control):
	"""Move bubble to target"""
	var target_pos = target.global_position + Vector2(10 * scale_factor, 5 * scale_factor)
	var tween = create_tween()
	tween.tween_property(bubble, "global_position", target_pos, 0.3)

func return_bubble_to_original_position(bubble: Control):
	"""Return bubble to original position"""
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	bubble.set_meta("is_dragging", false)
	bubble.z_index = 0
	bubble.scale = Vector2.ONE
	
	var original_position = bubble.get_meta("original_position", Vector2.ZERO)
	var bubble_parent = bubble.get_parent()
	if bubble_parent:
		var global_original_position = bubble_parent.global_position + original_position
		var tween = create_tween()
		tween.tween_property(bubble, "global_position", global_original_position, 0.3)

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
	
	var level_config = difficulty_levels[current_difficulty]
	var total_for_round = level_config["count"]
	score_label.text = "Score: %d/%d" % [correct_matches_this_round, total_for_round]
	
	if matches_remaining <= 0:
		complete_round()

func handle_incorrect_match():
	"""Handle wrong match"""
	if error_sound:
		error_sound.play()
	
	var messages = ["Try again! 🤔", "Almost! Keep going! 💪", "You've got this! 🎈", "Don't give up! 🌟"]
	show_feedback(messages[randi() % messages.size()], Color.ORANGE, 2.0)

func complete_round():
	"""Complete current round"""
	is_game_active = false
	
	if current_round < total_rounds:
		show_feedback("Round %d Complete! 🎉" % current_round, Color.GOLD)
		await get_tree().create_timer(2.0).timeout
		start_button.disabled = false
		start_button.text = "Next Round"
	else:
		complete_game()

func complete_game():
	"""Complete current difficulty level"""
	is_game_active = false
	show_feedback("🏆 %s Mode Complete! 🏆" % current_difficulty.capitalize(), Color.GOLD)
	await get_tree().create_timer(2.0).timeout
	show_completion_popup()

func show_completion_popup():
	"""Show completion popup"""
	var completion_text = ""
	var elapsed_time = Time.get_unix_time_from_system() - start_time
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	
	completion_text += "[center]🎊 [color=gold]%s DIFFICULTY COMPLETE![/color] 🎊[/center]\n\n" % current_difficulty.capitalize()
	completion_text += "[center]⏱️ Total Time: %02d:%02d[/center]\n" % [minutes, seconds]
	completion_text += "[center]🎯 Rounds Completed: %d/%d[/center]\n" % [current_round, total_rounds]
	completion_text += "[center]⭐ Total Matches: %d[/center]\n\n" % total_matches
	
	if current_difficulty == "easy":
		completion_text += "[center][color=cyan]🎯 Ready for Medium difficulty?[/color][/center]"
		next_round_button.text = "▶️ Play Medium"
	elif current_difficulty == "medium":
		completion_text += "[center][color=orange]🔥 Ready for Hard difficulty?[/color][/center]"
		next_round_button.text = "▶️ Play Hard"
	else:
		completion_text += "[center][color=gold]🌟 CONGRATULATIONS! 🌟[/color][/center]"
		next_round_button.text = "🎮 Play Again"
	
	results_label.text = completion_text
	finish_button.text = "➡️ Next Game"
	
	round_complete_popup.get_ok_button().hide()
	round_complete_popup.show()

func _on_next_round_pressed():
	"""Handle next difficulty button"""
	round_complete_popup.hide()
	
	if current_difficulty == "hard":
		current_difficulty = "easy"
	else:
		if current_difficulty == "easy":
			current_difficulty = "medium"
		elif current_difficulty == "medium":
			current_difficulty = "hard"
	
	reset_for_new_difficulty()

func reset_for_new_difficulty():
	"""Reset game for new difficulty and auto-start"""
	is_game_started = false
	current_round = 0
	total_matches = 0
	total_rounds = difficulty_levels[current_difficulty]["rounds"]
	
	update_rounds_display()
	start_button.text = "🎮 Start %s" % current_difficulty.capitalize()
	start_button.disabled = false
	
	# Clear feedback first, then show new difficulty message
	feedback_label.text = ""
	await get_tree().create_timer(0.3).timeout
	
	show_feedback("🎯 %s Mode Ready!" % current_difficulty.capitalize(), Color.CYAN, 2.5)
	
	# Auto-start the new difficulty
	await get_tree().create_timer(2.0).timeout
	auto_start_game()

func _on_finish_game_pressed():
	"""Handle next game button"""
	round_complete_popup.hide()
	get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")

func reset_game():
	"""Reset everything"""
	current_difficulty = "easy"
	is_game_started = false
	is_game_active = false
	current_round = 0
	total_matches = 0
	clear_dynamic_bubbles()
	
	start_button.text = "🎮 Start Game"
	start_button.disabled = false
	reset_button.disabled = true
	
	round_complete_popup.hide()
	
	timer_label.text = "Time: 00:00"
	score_label.text = "Score: 0/4"
	update_rounds_display()
	feedback_label.text = ""

func show_feedback(message: String, color: Color, duration: float = 4.0):
	"""Show feedback message"""
	# Clear any existing tween first
	var existing_tweens = get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if tween.is_valid():
			tween.kill()
	
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.scale = Vector2.ONE  # Reset scale
	
	var tween = create_tween()
	tween.tween_property(feedback_label, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.2)
	
	# Create a separate timer to clear the text
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		if feedback_label and is_instance_valid(feedback_label):
			feedback_label.text = ""
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func _on_reset_game():
	"""Reset button pressed"""
	reset_game()

func _on_options_pressed():
	"""Show difficulty options"""
	difficulty_popup.popup_centered()

func _on_back_to_menu():
	"""Return to menu"""
	get_tree().change_scene_to_file("res://Scenes/1 MainMenu.tscn")

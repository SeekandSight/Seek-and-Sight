extends Control

# Game state variables
var current_round = 1
var max_rounds = 2  # Changed from 5 to 2 rounds per difficulty
var shapes_per_round = 4
var current_score = 0
var game_active = false
var difficulty_level = 4  # Easy by default
var current_difficulty_name = "Easy"
var difficulty_progression = ["Easy", "Medium", "Hard"]
var current_difficulty_index = 0

# Shape data - corresponds to your asset files
var available_shapes = [
	{"name": "Circle", "image": "res://Assets/Images/Shapes/Circle.png", "audio": "res://Assets/Audio/Shapes/Circle.wav"},
	{"name": "Diamond", "image": "res://Assets/Images/Shapes/Diamond.png", "audio": "res://Assets/Audio/Shapes/Diamond.wav"},
	{"name": "Heart", "image": "res://Assets/Images/Shapes/Heart.png", "audio": "res://Assets/Audio/Shapes/Heart.wav"},
	{"name": "Oval", "image": "res://Assets/Images/Shapes/Oval.png", "audio": "res://Assets/Audio/Shapes/Oval.wav"},
	{"name": "Rectangle", "image": "res://Assets/Images/Shapes/Rectangle.png", "audio": "res://Assets/Audio/Shapes/Rectangle.wav"},
	{"name": "Square", "image": "res://Assets/Images/Shapes/Square.png", "audio": "res://Assets/Audio/Shapes/Square.wav"},
	{"name": "Star", "image": "res://Assets/Images/Shapes/Star.png", "audio": "res://Assets/Audio/Shapes/Star.wav"},
	{"name": "Triangle", "image": "res://Assets/Images/Shapes/Triangle.png", "audio": "res://Assets/Audio/Shapes/Triangle.wav"}
]

var current_round_shapes = []
var shape_cards = []
var target_slots = []
var matches_made = 0

# Drag and drop variables
var dragging_card = null
var drag_offset = Vector2.ZERO
var original_positions = {}

# UI References from your existing scene
@onready var timer_label = $UI/TimerContainer/TimerLabel
@onready var rounds_label = $UI/RoundsContainer/RoundsLabel  # Add this for rounds display
@onready var score_label = $UI/ScoreContainer/ScoreLabel
@onready var feedback_label = $UI/FeedbackLabel
@onready var card_container = $GameContainer/HBoxContainer/LeftColumn/ShapesBubble/CardContainer
@onready var target_container = $GameContainer/HBoxContainer/RightColumn/AnswerBubble/TargetContainer
@onready var start_button = $ControlsContainer/StartButton
@onready var options_button = $ControlsContainer/OptionsButton
@onready var reset_button = $ControlsContainer/ResetButton
@onready var back_button = $ControlsContainer/BackButton
@onready var difficulty_popup = $UI/DifficultyPopup
@onready var round_complete_popup = $UI/RoundCompletePopup
@onready var results_label = $UI/RoundCompletePopup/ResultsLabel
@onready var next_round_button = $UI/RoundCompletePopup/ButtonContainer/NextRoundButton
@onready var finish_button = $UI/RoundCompletePopup/ButtonContainer/FinishButton
@onready var success_sound = $Audio/SuccessSound
@onready var error_sound = $Audio/ErrorSound

func _ready():
	connect_signals()

func connect_signals():
	start_button.pressed.connect(_on_start_game)
	options_button.pressed.connect(_on_options_pressed)
	reset_button.pressed.connect(_on_reset_game)
	back_button.pressed.connect(_on_back_to_menu)
	next_round_button.pressed.connect(_on_next_round_handler)
	finish_button.pressed.connect(_on_finish_game_handler)
	
	# Update back button text
	if back_button:
		back_button.text = "⬅️ Back to Number Match"
	
	# Difficulty buttons
	$UI/DifficultyPopup/VBoxContainer/EasyButton.pressed.connect(func(): _set_difficulty(4))
	$UI/DifficultyPopup/VBoxContainer/MediumButton.pressed.connect(func(): _set_difficulty(6))
	$UI/DifficultyPopup/VBoxContainer/HardButton.pressed.connect(func(): _set_difficulty(8))

func _on_next_round_handler():
	if easy_mode_complete:
		_on_next_round_post_easy()
	elif medium_mode_complete:
		_on_next_round_post_medium()
	elif hard_mode_complete:
		_on_next_round_post_hard()
	else:
		_on_next_round()

func _on_finish_game_handler():
	if easy_mode_complete:
		_on_finish_post_easy()
	elif medium_mode_complete:
		_on_finish_post_medium()
	elif hard_mode_complete:
		_on_finish_post_hard()
	else:
		_on_finish_game()

func _on_start_game():
	# Show difficulty popup instead of starting immediately
	difficulty_popup.popup_centered()

func _on_options_pressed():
	difficulty_popup.popup_centered()

func _set_difficulty(num_shapes: int):
	difficulty_level = num_shapes
	# Set difficulty index and name
	if num_shapes == 4:
		current_difficulty_index = 0
		current_difficulty_name = "Easy"
	elif num_shapes == 6:
		current_difficulty_index = 1
		current_difficulty_name = "Medium"
	elif num_shapes == 8:
		current_difficulty_index = 2
		current_difficulty_name = "Hard"
	difficulty_popup.hide()
	
	# Automatically start the game
	start_game()

func _on_back_to_menu():
	# Go back to Number Match game (minigame_1)
	get_tree().change_scene_to_file("res://Scenes/minigame_1.tscn")

func start_game():
	game_active = true
	current_round = 1
	current_score = 0
	matches_made = 0
	
	# Show the rounds container when game starts
	if $UI/RoundsContainer:
		$UI/RoundsContainer.visible = true
	
	start_round()

func start_round():
	if current_round > max_rounds:
		end_game()
		return
	
	# Clear previous round
	clear_containers()
	matches_made = 0
	shape_cards.clear()
	target_slots.clear()
	original_positions.clear()
	
	# Update shapes per round based on difficulty
	shapes_per_round = difficulty_level
	
	# Select random shapes for this round
	current_round_shapes = available_shapes.duplicate()
	current_round_shapes.shuffle()
	current_round_shapes = current_round_shapes.slice(0, shapes_per_round)
	
	create_shape_cards()
	create_target_slots()
	update_ui()
	
	feedback_label.text = "Drag shapes to their matching names!"
	feedback_label.modulate = Color.WHITE

func create_shape_cards():
	# Dynamic layout based on number of shapes
	var grid_cols = 2
	var card_size = Vector2(100, 100)
	var spacing_x = 15
	var spacing_y = 15
	
	# Determine optimal grid layout
	if shapes_per_round == 4:
		grid_cols = 2  # 2x2 grid
		card_size = Vector2(120, 120)
		spacing_x = 20
		spacing_y = 20
	elif shapes_per_round == 6:
		grid_cols = 3  # 3x2 grid
		card_size = Vector2(110, 110)
		spacing_x = 18
		spacing_y = 18
	elif shapes_per_round == 8:
		grid_cols = 3 # 3x3 grid for better fit
		card_size = Vector2(90, 90)
		spacing_x = 12
		spacing_y = 15
	
	# Calculate total grid dimensions
	var total_rows = (shapes_per_round + grid_cols - 1) / grid_cols  # Ceiling division
	var total_width = grid_cols * card_size.x + (grid_cols - 1) * spacing_x
	var total_height = total_rows * card_size.y + (total_rows - 1) * spacing_y
	
	# Center the grid in the container (assuming container is about 400px wide)
	var container_width = 380
	var container_height = 400
	var start_x = (container_width - total_width) / 2
	var start_y = 60  # Leave space for header
	
	for i in range(current_round_shapes.size()):
		var shape_data = current_round_shapes[i]
		var card = create_draggable_shape(shape_data, i, card_size)
		
		# Position cards in a grid
		var row = i / grid_cols
		var col = i % grid_cols
		var pos_x = start_x + col * (card_size.x + spacing_x)
		var pos_y = start_y + row * (card_size.y + spacing_y)
		
		card.position = Vector2(pos_x, pos_y)
		original_positions[card] = card.position
		card_container.add_child(card)
		shape_cards.append(card)

func create_target_slots():
	# Dynamic layout based on number of shapes
	var grid_cols = 2
	var slot_size = Vector2(100, 60)
	var spacing_x = 15
	var spacing_y = 15
	
	# Determine optimal grid layout matching the shape cards
	if shapes_per_round == 4:
		grid_cols = 2  # 2x2 grid
		slot_size = Vector2(120, 70)
		spacing_x = 20
		spacing_y = 20
	elif shapes_per_round == 6:
		grid_cols = 3  # 3x2 grid
		slot_size = Vector2(110, 65)
		spacing_x = 18
		spacing_y = 18
	elif shapes_per_round == 8:
		grid_cols = 3 # 3x3 grid for better fit
		slot_size = Vector2(90, 55)
		spacing_x = 12
		spacing_y = 15
	
	# Calculate total grid dimensions
	var total_rows = (shapes_per_round + grid_cols - 1) / grid_cols  # Ceiling division
	var total_width = grid_cols * slot_size.x + (grid_cols - 1) * spacing_x
	var total_height = total_rows * slot_size.y + (total_rows - 1) * spacing_y
	
	# Center the grid in the container (assuming container is about 400px wide)
	var container_width = 380
	var container_height = 400
	var start_x = (container_width - total_width) / 2
	var start_y = 60  # Leave space for header
	
	# Create shuffled list of shape names for targets
	var target_names = []
	for shape in current_round_shapes:
		target_names.append(shape.name)
	target_names.shuffle()
	
	for i in range(target_names.size()):
		var target_slot = create_drop_target(target_names[i], i, slot_size)
		
		# Position targets in a grid
		var row = i / grid_cols
		var col = i % grid_cols
		var pos_x = start_x + col * (slot_size.x + spacing_x)
		var pos_y = start_y + row * (slot_size.y + spacing_y)
		
		target_slot.position = Vector2(pos_x, pos_y)
		target_container.add_child(target_slot)
		target_slots.append(target_slot)

func create_draggable_shape(shape_data: Dictionary, index: int, card_size: Vector2) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = card_size
	card.name = "ShapeCard_" + str(index)
	
	# Style the card
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1, 1, 1, 0.9)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.6, 1, 1)
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_right = 12
	style_box.corner_radius_bottom_left = 12
	card.add_theme_stylebox_override("panel", style_box)
	
	# Add shape image
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(shape_data.image)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Special handling for Rectangle shape - make it smaller
	var padding = 6
	if shape_data.name == "Rectangle":
		padding = 20  # Much more padding to make rectangle smaller
		# Use FIT mode to contain the rectangle within bounds
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, padding)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let the panel handle mouse events
	
	card.add_child(texture_rect)
	card.set_meta("shape_data", shape_data)
	card.set_meta("matched", false)
	card.set_meta("index", index)
	
	# Connect mouse events for drag and drop
	card.gui_input.connect(_on_card_input.bind(card))
	
	return card

func create_drop_target(shape_name: String, index: int, slot_size: Vector2) -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = slot_size
	slot.name = "TargetSlot_" + str(index)
	
	# Style the target slot
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1, 0.95, 0.9, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1, 0.6, 0.4, 1)
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_right = 12
	style_box.corner_radius_bottom_left = 12
	slot.add_theme_stylebox_override("panel", style_box)
	
	# Add label with shape name
	var label = Label.new()
	label.text = shape_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Adjust font size based on slot size and difficulty
	var font_size = 14
	if shapes_per_round == 4:
		font_size = 16
	elif shapes_per_round == 6:
		font_size = 14
	elif shapes_per_round == 8:
		font_size = 12
	
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Enable text wrapping for longer shape names
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	slot.add_child(label)
	slot.set_meta("target_name", shape_name)
	slot.set_meta("filled", false)
	
	return slot

func _on_card_input(event: InputEvent, card: Control):
	if not game_active or card.get_meta("matched", false):
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				start_drag(card, event.position)
			else:
				# Stop dragging
				stop_drag(card)
	
	elif event is InputEventMouseMotion and dragging_card == card:
		# Continue dragging
		card.global_position = get_global_mouse_position() - drag_offset

func start_drag(card: Control, click_position: Vector2):
	dragging_card = card
	drag_offset = click_position
	
	# Bring card to front
	card.z_index = 100
	
	# Visual feedback - make it slightly transparent
	card.modulate = Color(1, 1, 1, 0.8)
	
	# Scale up slightly to show it's being dragged
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.1)

func stop_drag(card: Control):
	if dragging_card != card:
		return
	
	dragging_card = null
	card.z_index = 0
	card.modulate = Color(1, 1, 1, 1.0)
	
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Check if dropped on a valid target
	var dropped_target = find_target_under_card(card)
	
	if dropped_target:
		attempt_match(card, dropped_target)
	else:
		# Return to original position
		return_to_original_position(card)

func find_target_under_card(card: Control) -> Control:
	var card_center = card.global_position + card.size / 2
	
	for target in target_slots:
		if target.get_meta("filled", false):
			continue
			
		var target_rect = Rect2(target.global_position, target.size)
		if target_rect.has_point(card_center):
			return target
	
	return null

func attempt_match(card: Control, target: Control):
	var shape_data = card.get_meta("shape_data")
	var target_name = target.get_meta("target_name")
	
	if shape_data.name == target_name:
		# Correct match!
		perform_correct_match(card, target)
	else:
		# Incorrect match
		perform_incorrect_match(card, target)

func perform_correct_match(card: Control, target: Control):
	var shape_data = card.get_meta("shape_data")
	
	# Mark as matched
	card.set_meta("matched", true)
	target.set_meta("filled", true)
	
	# Update score
	current_score += 1
	matches_made += 1
	
	# Visual and audio feedback
	feedback_label.text = "✓ Correct! " + shape_data.name + " matched!"
	feedback_label.modulate = Color.GREEN
	
	if success_sound and success_sound.stream:
		success_sound.play()
	
	# Animate card to center of target
	var tween = create_tween()
	var target_center = target.global_position + (target.size - card.size) / 2
	tween.tween_property(card, "global_position", target_center, 0.3)
	tween.tween_callback(func():
		# Change visual appearance to show success
		card.modulate = Color(0.8, 1.0, 0.8, 0.7)
		target.modulate = Color(0.8, 1.0, 0.8, 1.0)
	)
	
	update_ui()
	
	# Check if round is complete
	if matches_made >= shapes_per_round:
		await get_tree().create_timer(1.0).timeout
		complete_round()

func perform_incorrect_match(card: Control, target: Control):
	# Visual and audio feedback for incorrect match
	feedback_label.text = "✗ Try again! That's not the right match."
	feedback_label.modulate = Color.RED
	
	if error_sound and error_sound.stream:
		error_sound.play()
	
	# Flash the target red briefly
	var original_color = target.modulate
	target.modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	target.modulate = original_color
	
	# Return card to original position
	return_to_original_position(card)

func return_to_original_position(card: Control):
	var original_pos = original_positions.get(card, Vector2.ZERO)
	var tween = create_tween()
	tween.tween_property(card, "global_position", card_container.global_position + original_pos, 0.4)
	tween.tween_callback(func():
		feedback_label.text = "Drag shapes to their matching names!"
		feedback_label.modulate = Color.WHITE
	)

# Add a variable to track if we need special handling for different modes
var easy_mode_complete = false
var medium_mode_complete = false
var hard_mode_complete = false

func complete_round():
	# Show round complete popup
	var results_text = "[center][b]Round " + str(current_round) + " Complete![/b][/center]\n\n"
	results_text += "Difficulty: " + current_difficulty_name + " Mode\n"
	results_text += "Shapes matched: " + str(matches_made) + "/" + str(shapes_per_round) + "\n"
	results_text += "Score this round: " + str(matches_made) + "\n"
	results_text += "Total score: " + str(current_score) + "\n\n"
	
	var matched_names = []
	for shape in current_round_shapes:
		matched_names.append(shape.name)
	results_text += "Shapes in this round: " + ", ".join(matched_names)
	
	results_label.text = results_text
	
	if current_round >= max_rounds:
		# Completed all rounds in this difficulty
		if current_difficulty_name == "Easy":
			easy_mode_complete = true
			medium_mode_complete = false
			hard_mode_complete = false
			next_round_button.visible = true
			next_round_button.text = "🎯 Play Medium Mode"
			finish_button.visible = true
			finish_button.text = "🔥 Skip to Hard Mode"
		elif current_difficulty_name == "Medium":
			easy_mode_complete = false
			medium_mode_complete = true
			hard_mode_complete = false
			next_round_button.visible = true
			next_round_button.text = "🔥 Play Hard Mode"
			finish_button.visible = true
			finish_button.text = "🎮 Next Game"
		elif current_difficulty_name == "Hard":
			easy_mode_complete = false
			medium_mode_complete = false
			hard_mode_complete = true
			next_round_button.visible = true
			next_round_button.text = "🔄 Play Again"
			finish_button.visible = true
			finish_button.text = "🎮 Next Game"
	else:
		# More rounds in current difficulty
		easy_mode_complete = false
		medium_mode_complete = false
		hard_mode_complete = false
		next_round_button.visible = true
		next_round_button.text = "➡️ Next Round"
		finish_button.visible = true
		finish_button.text = "🎮 Next Game"
	
	round_complete_popup.popup_centered()

func _on_next_round():
	round_complete_popup.hide()
	
	# Check if we're advancing to next difficulty or next round
	if current_round >= max_rounds:
		# Completed all rounds, advance to next difficulty
		if current_difficulty_name == "Easy":
			# Special handling for Easy mode - go to Medium
			advance_to_specific_difficulty("Medium")
		else:
			advance_to_next_difficulty()
	else:
		# Continue to next round in current difficulty
		current_round += 1
		start_round()

func advance_to_specific_difficulty(target_difficulty: String):
	# Set specific difficulty
	current_difficulty_name = target_difficulty
	if target_difficulty == "Medium":
		current_difficulty_index = 1
		difficulty_level = 6
	elif target_difficulty == "Hard":
		current_difficulty_index = 2
		difficulty_level = 8
	
	# Reset for new difficulty
	current_round = 1
	current_score = 0
	
	# Start new difficulty
	start_round()
	
	# Show notification
	feedback_label.text = "🎯 Starting " + current_difficulty_name + " Mode!"
	feedback_label.modulate = Color.CYAN

func advance_to_next_difficulty():
	if current_difficulty_index < difficulty_progression.size() - 1:
		# Move to next difficulty
		current_difficulty_index += 1
		current_difficulty_name = difficulty_progression[current_difficulty_index]
		
		# Set new difficulty parameters
		if current_difficulty_name == "Medium":
			difficulty_level = 6
		elif current_difficulty_name == "Hard":
			difficulty_level = 8
		
		# Reset for new difficulty
		current_round = 1
		current_score = 0
		
		# Start new difficulty
		start_round()
		
		# Show notification
		feedback_label.text = "🎯 Starting " + current_difficulty_name + " Mode!"
		feedback_label.modulate = Color.CYAN
	else:
		# All difficulties complete, restart from Easy
		_on_reset_game()

func _on_finish_game():
	round_complete_popup.hide()
	
	# Special handling for different mode completions
	if easy_mode_complete:
		# Show difficulty selection popup
		show_post_easy_difficulty_selection()
	elif medium_mode_complete or hard_mode_complete:
		# Go to next game (minigame_3)
		go_to_next_game()
	else:
		# Go to next game (minigame_3)
		go_to_next_game()

func go_to_next_game():
	feedback_label.text = "🎮 Going to Next Game..."
	feedback_label.modulate = Color.GREEN
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://Scenes/minigame_3.tscn")

func show_post_easy_difficulty_selection():
	# Create a custom selection for post-Easy mode
	var selection_text = "[center][b]🎉 Easy Mode Complete![/b][/center]\n\n"
	selection_text += "Choose your next challenge:\n\n"
	selection_text += "🎯 Medium Mode (6 Shapes)\n"
	selection_text += "🔥 Hard Mode (8 Shapes)\n"
	selection_text += "🎮 Next Game"
	
	results_label.text = selection_text
	
	# Update buttons for three options
	next_round_button.visible = true
	next_round_button.text = "🎯 Medium Mode"
	finish_button.visible = true
	finish_button.text = "🔥 Skip to Hard Mode"
	
	round_complete_popup.popup_centered()

# Override button behavior when in post-Easy selection
func _on_next_round_post_easy():
	round_complete_popup.hide()
	advance_to_specific_difficulty("Medium")

func _on_finish_post_easy():
	round_complete_popup.hide()
	advance_to_specific_difficulty("Hard")

# Medium mode completion handlers
func _on_next_round_post_medium():
	round_complete_popup.hide()
	advance_to_specific_difficulty("Hard")

func _on_finish_post_medium():
	round_complete_popup.hide()
	go_to_next_game()

# Hard mode completion handlers
func _on_next_round_post_hard():
	round_complete_popup.hide()
	# Play again - restart from Easy
	_on_reset_game()

func _on_finish_post_hard():
	round_complete_popup.hide()
	go_to_next_game()

func end_game():
	game_active = false
	
	feedback_label.text = "🎉 " + current_difficulty_name + " Mode Complete! Score: " + str(current_score) + "/" + str(max_rounds * shapes_per_round)
	feedback_label.modulate = Color.YELLOW
	
	# Check if there's a next difficulty level
	if current_difficulty_index < difficulty_progression.size() - 1:
		# Show difficulty completion popup with next level option
		show_difficulty_complete_popup()
	else:
		# All difficulties completed
		show_all_difficulties_complete_popup()

func show_difficulty_complete_popup():
	var results_text = "[center][b]🎉 " + current_difficulty_name + " Mode Complete![/b][/center]\n\n"
	results_text += "Final Score: " + str(current_score) + "/" + str(max_rounds * shapes_per_round) + "\n\n"
	results_text += "Great job! You completed " + current_difficulty_name + " mode in just 2 rounds!\n\n"
	
	if current_difficulty_name == "Easy":
		results_text += "What would you like to play next?"
		results_label.text = results_text
		
		# Show multiple difficulty options after Easy
		next_round_button.visible = true
		next_round_button.text = "🎯 Play Medium Mode"
		finish_button.visible = true
		finish_button.text = "🔥 Play Hard Mode"
		
		# Add a third option for Next Game (we'll use a custom approach)
		show_easy_complete_options()
	else:
		# For Medium and Hard, show next difficulty or completion
		if current_difficulty_index < difficulty_progression.size() - 1:
			var next_difficulty = difficulty_progression[current_difficulty_index + 1]
			results_text += "Ready for " + next_difficulty + " mode?"
			results_label.text = results_text
			
			next_round_button.visible = true
			next_round_button.text = "🎯 Play " + next_difficulty + " Mode"
			finish_button.visible = true
			finish_button.text = "🎮 Next Game"
		else:
			# Hard mode complete
			show_all_difficulties_complete_popup()
			return
	
	round_complete_popup.popup_centered()

func show_easy_complete_options():
	# Create custom popup for Easy mode completion with 3 options
	var easy_complete_text = "[center][b]🎉 Easy Mode Complete![/b][/center]\n\n"
	easy_complete_text += "Final Score: " + str(current_score) + "/" + str(max_rounds * shapes_per_round) + "\n\n"
	easy_complete_text += "Great job! You completed Easy mode!\n\n"
	easy_complete_text += "Choose your next challenge:"
	
	results_label.text = easy_complete_text
	
	# Customize buttons for Easy completion
	next_round_button.visible = true
	next_round_button.text = "🎯 Medium Mode (6 Shapes)"
	finish_button.visible = true
	finish_button.text = "🎮 Next Game"
	
	# We'll modify the button handler to check for special case

func show_all_difficulties_complete_popup():
	var results_text = "[center][b]🏆 ALL DIFFICULTIES COMPLETE![/b][/center]\n\n"
	results_text += "Amazing! You've mastered all difficulty levels!\n\n"
	results_text += "Easy Mode (2 rounds): Complete ✓\n"
	results_text += "Medium Mode (2 rounds): Complete ✓\n"
	results_text += "Hard Mode (2 rounds): Complete ✓\n\n"
	results_text += "You're a Shape Matching Master!"
	
	results_label.text = results_text
	
	# Only show options to replay or go to next game
	next_round_button.visible = true
	next_round_button.text = "🔄 Play Again"
	finish_button.visible = true
	finish_button.text = "🎮 Next Game"
	
	round_complete_popup.popup_centered()

func _on_reset_game():
	# Reset all game state
	game_active = false
	current_round = 1
	current_score = 0
	matches_made = 0
	dragging_card = null
	current_difficulty_index = 0
	current_difficulty_name = "Easy"
	difficulty_level = 4
	
	# Reset completion flags
	easy_mode_complete = false
	medium_mode_complete = false
	hard_mode_complete = false
	
	# Hide the rounds container when game resets
	if $UI/RoundsContainer:
		$UI/RoundsContainer.visible = false
	
	# Clear containers
	clear_containers()
	shape_cards.clear()
	target_slots.clear()
	original_positions.clear()
	
	# Reset feedback
	feedback_label.text = ""
	feedback_label.modulate = Color.WHITE
	
	# Hide popups
	round_complete_popup.hide()
	difficulty_popup.hide()
	
	# Reset UI
	update_ui()

func clear_containers():
	# Clear previous cards and targets
	for child in card_container.get_children():
		child.queue_free()
	for child in target_container.get_children():
		child.queue_free()

func update_ui():
	score_label.text = "Score: " + str(current_score) + "/" + str(max_rounds * shapes_per_round)
	
	# Update timer label for time display (you can add actual timing logic here)
	timer_label.text = "Time: 00:00"
	
	# Update rounds label with difficulty and round info
	if rounds_label:
		rounds_label.text = current_difficulty_name + " - Round: " + str(current_round) + "/2"

# Override _input to handle global mouse events during dragging
func _input(event):
	if dragging_card and event is InputEventMouseMotion:
		dragging_card.global_position = get_global_mouse_position() - drag_offset

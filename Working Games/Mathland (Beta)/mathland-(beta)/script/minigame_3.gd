extends Control
func generate_initial_display():
	print("Generating initial display...")
	current_count = 1
	
	# Clear existing content
	clear_all_buttons()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Create content but don't make it interactive yet
	create_number_buttons()
	create_progress_indicators()
	update_ui_labels()
	update_math_sprite_expression("neutral")
	show_feedback("Click Start Game to begin!", 0.0)
	
	# Disable all buttons initially
	for button in buttons_array:
		button.disabled = true
		# Style disabled buttons differently
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color.LIGHT_GRAY
		disabled_style.border_width_left = 2
		disabled_style.border_width_top = 2
		disabled_style.border_width_right = 2
		disabled_style.border_width_bottom = 2
		disabled_style.border_color = Color.GRAY
		disabled_style.corner_radius_top_left = 15
		disabled_style.corner_radius_top_right = 15
		disabled_style.corner_radius_bottom_left = 15
		disabled_style.corner_radius_bottom_right = 15
		button.add_theme_stylebox_override("disabled", disabled_style)
	
	print("Initial display generated with ", target_number, " numbers")

# Game variables
var target_number: int = 10
var current_count: int = 1
var difficulty: String = "easy"
var game_started: bool = false
var game_active: bool = false
var buttons_array: Array = []
var round_number: int = 1
var correct_answers: int = 0
var completed_difficulties: Array = []

# Difficulty settings with rounds
var difficulty_settings = {
	"easy": {
		"min": 5, 
		"max": 10, 
		"rounds": 3,
		"description": "Count to 5-10"
	},
	"medium": {
		"min": 11, 
		"max": 20, 
		"rounds": 4,
		"description": "Count to 11-20"
	},
	"hard": {
		"min": 21, 
		"max": 30, 
		"rounds": 5,
		"description": "Count to 21-30"
	}
}

var difficulty_order = ["easy", "medium", "hard"]

# Node references
@onready var game_container = $GameContainer
@onready var controls_container = $ControlsContainer
@onready var character_area = $CharacterArea

# UI Elements
@onready var timer_container = $UI/TimerContainer
@onready var timer_label = $UI/TimerContainer/TimerLabel
@onready var score_label = $UI/ScoreContainer/ScoreLabel
@onready var rounds_label = $UI/RoundsContainer/RoundsLabel
@onready var feedback_label = $UI/FeedbackLabel

# Game UI
@onready var number_grid = $GameContainer/HBoxContainer/LeftColumn/NumbersBubble/NumberGrid
@onready var target_label = $GameContainer/HBoxContainer/RightColumn/TargetBubble/TargetLabel
@onready var progress_grid = $GameContainer/HBoxContainer/RightColumn/ProgressBubble/ProgressGrid
@onready var next_step_label = $GameContainer/HBoxContainer/MiddleColumn/NextStepLabel
@onready var math_sprite = $GameContainer/HBoxContainer/MiddleColumn/MathCharacter/MathSprite

# Control buttons
@onready var start_button = $ControlsContainer/StartButton
@onready var options_button = $ControlsContainer/OptionsButton
@onready var back_button = $ControlsContainer/BackButton
@onready var reset_button = $ControlsContainer/ResetButton

# Popups
@onready var difficulty_popup = $UI/DifficultyPopup
@onready var round_complete_popup = $UI/RoundCompletePopup
@onready var results_label = $UI/RoundCompletePopup/ResultsLabel
@onready var next_round_button = $UI/RoundCompletePopup/ButtonContainer/NextRoundButton
@onready var finish_button = $UI/RoundCompletePopup/ButtonContainer/FinishButton

# Difficulty buttons
@onready var easy_button = $UI/DifficultyPopup/VBoxContainer/EasyButton
@onready var medium_button = $UI/DifficultyPopup/VBoxContainer/MediumButton
@onready var hard_button = $UI/DifficultyPopup/VBoxContainer/HardButton

# Audio
@onready var success_sound = $Audio/SuccessSound
@onready var error_sound = $Audio/ErrorSound
@onready var background_music = $Audio/BackgroundMusic

func _ready():
	# Wait for all nodes to be ready
	await get_tree().process_frame
	setup_initial_state()
	connect_buttons()

func setup_initial_state():
	print("Setting up initial state...")
	
	# Show both main menu AND game area initially
	if game_container:
		game_container.visible = true
		print("Game container shown")
	
	if controls_container:
		controls_container.visible = true
		print("Controls container shown")
	if character_area:
		character_area.visible = true
		print("Character area shown")
	
	# Hide timer completely (not needed)
	if timer_container:
		timer_container.visible = false
	
	# Initialize game state
	difficulty = "easy"
	round_number = 1
	completed_difficulties = []
	
	# Set default difficulty and show initial round
	set_difficulty("easy")
	generate_initial_display()
	
	print("Initial state setup complete")

func start_game():
	print("Starting game...")
	game_active = true
	game_started = true
	round_number = 1
	correct_answers = 0
	
	# Don't hide the controls, keep everything visible
	# Just enable the game buttons
	for button in buttons_array:
		button.disabled = false
		
		# Re-apply normal button styling
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color.WHITE
		normal_style.border_width_left = 3
		normal_style.border_width_top = 3
		normal_style.border_width_right = 3
		normal_style.border_width_bottom = 3
		normal_style.border_color = Color.BLUE
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_left = 15
		normal_style.corner_radius_bottom_right = 15
		button.add_theme_stylebox_override("normal", normal_style)
	
	update_ui_labels()
	show_feedback("", 0.0)
	print("Game started - buttons enabled")

func update_ui_labels():
	if score_label:
		score_label.text = "Progress: " + str(current_count - 1) + "/" + str(target_number)
	if rounds_label:
		var max_rounds = difficulty_settings[difficulty].rounds
		rounds_label.text = "Round: " + str(round_number) + "/" + str(max_rounds)
	if next_step_label:
		next_step_label.text = "Click: " + str(current_count)
	if target_label:
		target_label.text = str(target_number)

func set_difficulty(new_difficulty: String):
	if new_difficulty in difficulty_settings:
		difficulty = new_difficulty
		var range_data = difficulty_settings[difficulty]
		target_number = randi_range(range_data.min, range_data.max)
		print("Difficulty set to: ", difficulty, " Target: ", target_number)
		
		# Update the difficulty button texts to show the new selection
		update_difficulty_button_texts()
		update_ui_labels()

func update_difficulty_button_texts():
	# Update button texts to show rounds information
	if easy_button:
		if difficulty == "easy":
			easy_button.text = "✓ Easy (3 rounds: count 5-10) - SELECTED"
		else:
			easy_button.text = "😊 Easy (3 rounds: count 5-10)"
	
	if medium_button:
		if difficulty == "medium":
			medium_button.text = "✓ Medium (4 rounds: count 11-20) - SELECTED"
		else:
			medium_button.text = "🎯 Medium (4 rounds: count 11-20)"
	
	if hard_button:
		if difficulty == "hard":
			hard_button.text = "✓ Hard (5 rounds: count 21-30) - SELECTED"
		else:
			hard_button.text = "🔥 Hard (5 rounds: count 21-30)"

func generate_new_round():
	print("Generating new round...")
	current_count = 1
	
	# Clear existing content
	clear_all_buttons()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Create new content
	create_number_buttons()
	create_progress_indicators()
	update_ui_labels()
	update_math_sprite_expression("neutral")
	show_feedback("", 0.0)
	
	# Make sure buttons are enabled if game is active
	if game_started and game_active:
		for button in buttons_array:
			button.disabled = false
	
	print("Round generated with ", target_number, " numbers")

func clear_all_buttons():
	print("Clearing buttons...")
	buttons_array.clear()
	
	# Clear number grid
	if number_grid:
		for child in number_grid.get_children():
			child.queue_free()
		print("Number grid cleared")
	
	# Clear progress grid
	if progress_grid:
		for child in progress_grid.get_children():
			child.queue_free()
		print("Progress grid cleared")

func create_number_buttons():
	if not number_grid:
		print("Error: number_grid not found!")
		return
		
	print("Creating ", target_number, " number buttons...")
	
	# Create array of numbers from 1 to target_number
	var numbers = []
	for i in range(1, target_number + 1):
		numbers.append(i)
	
	# Shuffle the numbers
	numbers.shuffle()
	print("Numbers shuffled: ", numbers)
	
	# Calculate button size based on number of buttons
	var button_size = calculate_button_size(target_number)
	var font_size = calculate_font_size(target_number)
	
	# Create buttons in grid
	for i in range(target_number):
		var button = Button.new()
		button.text = str(numbers[i])
		button.custom_minimum_size = button_size
		button.add_theme_font_size_override("font_size", font_size)
		button.add_theme_color_override("font_color", Color.BLACK)
		
		# Style the button
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color.BLACK
		normal_style.border_width_left = 3
		normal_style.border_width_top = 3
		normal_style.border_width_right = 3
		normal_style.border_width_bottom = 3
		normal_style.border_color = Color.BLUE
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_left = 15
		normal_style.corner_radius_bottom_right = 15
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color.LIGHT_BLUE
		hover_style.border_width_left = 3
		hover_style.border_width_top = 3
		hover_style.border_width_right = 3
		hover_style.border_width_bottom = 3
		hover_style.border_color = Color.BLUE
		hover_style.corner_radius_top_left = 15
		hover_style.corner_radius_top_right = 15
		hover_style.corner_radius_bottom_left = 15
		hover_style.corner_radius_bottom_right = 15
		
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", hover_style)
		
		# Connect button signal
		button.pressed.connect(_on_number_button_pressed.bind(int(button.text)))
		
		number_grid.add_child(button)
		buttons_array.append(button)
	
	print("Created ", buttons_array.size(), " buttons")

func calculate_button_size(num_buttons: int) -> Vector2:
	# Adjust button size based on number of buttons
	if num_buttons <= 10:
		return Vector2(70, 70)
	elif num_buttons <= 20:
		return Vector2(70, 70)
	else:
		return Vector2(60, 60)

func calculate_font_size(num_buttons: int) -> int:
	# Adjust font size based on number of buttons
	if num_buttons <= 10:
		return 24
	elif num_buttons <= 20:
		return 20
	else:
		return 18

func create_progress_indicators():
	if not progress_grid:
		print("Error: progress_grid not found!")
		return
		
	print("Creating progress indicators...")
	
	# Create small progress indicators showing which numbers have been clicked
	for i in range(1, target_number + 1):
		var progress_panel = Panel.new()
		progress_panel.custom_minimum_size = Vector2(40, 40)
		
		var progress_style = StyleBoxFlat.new()
		progress_style.bg_color = Color.LIGHT_GRAY
		progress_style.border_width_left = 2
		progress_style.border_width_top = 2
		progress_style.border_width_right = 2
		progress_style.border_width_bottom = 2
		progress_style.border_color = Color.GRAY
		progress_style.corner_radius_top_left = 10
		progress_style.corner_radius_top_right = 10
		progress_style.corner_radius_bottom_left = 10
		progress_style.corner_radius_bottom_right = 10
		
		progress_panel.add_theme_stylebox_override("panel", progress_style)
		
		var progress_label = Label.new()
		progress_label.text = str(i)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color.BLACK)
		progress_label.anchors_preset = Control.PRESET_FULL_RECT
		
		progress_panel.add_child(progress_label)
		progress_grid.add_child(progress_panel)

func _on_number_button_pressed(number: int):
	if not game_started or not game_active:
		print("Game not active, ignoring button press")
		return
	
	print("Button pressed: ", number, " Expected: ", current_count)
	
	if number == current_count:
		# Correct number clicked
		handle_correct_answer(number)
	else:
		# Wrong number clicked
		handle_wrong_answer(number)

func handle_correct_answer(number: int):
	print("Correct answer: ", number)
	
	# Find and disable the correct button
	for button in buttons_array:
		if button.text == str(number) and not button.disabled:
			button.disabled = true
			
			# Change button appearance to show it's been clicked
			var correct_style = StyleBoxFlat.new()
			correct_style.bg_color = Color.GREEN
			correct_style.border_width_left = 3
			correct_style.border_width_top = 3
			correct_style.border_width_right = 3
			correct_style.border_width_bottom = 3
			correct_style.border_color = Color.DARK_GREEN
			correct_style.corner_radius_top_left = 15
			correct_style.corner_radius_top_right = 15
			correct_style.corner_radius_bottom_left = 15
			correct_style.corner_radius_bottom_right = 15
			
			button.add_theme_stylebox_override("normal", correct_style)
			button.add_theme_stylebox_override("disabled", correct_style)
			break
	
	# Update progress indicator
	update_progress_indicator(number, true)
	
	# Play success sound
	if success_sound and success_sound.stream:
		success_sound.play()
	
	current_count += 1
	update_math_sprite_expression("happy")
	update_ui_labels()
	show_feedback("Great!", 1.0)
	
	# Check if round is completed
	if current_count > target_number:
		complete_round()

func handle_wrong_answer(number: int):
	print("Wrong answer! Expected: ", current_count, " Got: ", number)
	update_math_sprite_expression("sad")
	show_feedback("Try " + str(current_count) + "!", 2.0)
	
	# Play error sound
	if error_sound and error_sound.stream:
		error_sound.play()
	
	# Flash red briefly
	for button in buttons_array:
		if button.text == str(number):
			var wrong_style = StyleBoxFlat.new()
			wrong_style.bg_color = Color.RED
			wrong_style.border_color = Color.DARK_RED
			wrong_style.corner_radius_top_left = 15
			wrong_style.corner_radius_top_right = 15
			wrong_style.corner_radius_bottom_left = 15
			wrong_style.corner_radius_bottom_right = 15
			button.add_theme_stylebox_override("normal", wrong_style)
			
			# Reset after a short delay
			await get_tree().create_timer(0.3).timeout
			
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color.WHITE
			normal_style.border_width_left = 3
			normal_style.border_width_top = 3
			normal_style.border_width_right = 3
			normal_style.border_width_bottom = 3
			normal_style.border_color = Color.BLUE
			normal_style.corner_radius_top_left = 15
			normal_style.corner_radius_top_right = 15
			normal_style.corner_radius_bottom_left = 15
			normal_style.corner_radius_bottom_right = 15
			
			button.add_theme_stylebox_override("normal", normal_style)
			break

func update_progress_indicator(number: int, completed: bool):
	if not progress_grid:
		return
		
	# Update the progress grid indicator
	var progress_panels = progress_grid.get_children()
	if number <= progress_panels.size():
		var panel = progress_panels[number - 1]
		var progress_style = StyleBoxFlat.new()
		
		if completed:
			progress_style.bg_color = Color.GREEN
			progress_style.border_color = Color.DARK_GREEN
		else:
			progress_style.bg_color = Color.LIGHT_GRAY
			progress_style.border_color = Color.GRAY
		
		progress_style.border_width_left = 2
		progress_style.border_width_top = 2
		progress_style.border_width_right = 2
		progress_style.border_width_bottom = 2
		progress_style.corner_radius_top_left = 10
		progress_style.corner_radius_top_right = 10
		progress_style.corner_radius_bottom_left = 10
		progress_style.corner_radius_bottom_right = 10
		
		panel.add_theme_stylebox_override("panel", progress_style)

func show_feedback(message: String, duration: float):
	if feedback_label:
		feedback_label.text = message
		feedback_label.modulate = Color.WHITE
		
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			feedback_label.text = ""

func complete_round():
	print("Round completed!")
	game_started = false
	correct_answers = target_number
	update_math_sprite_expression("excited")
	show_feedback("Perfect! All numbers in order!", 3.0)
	
	var max_rounds = difficulty_settings[difficulty].rounds
	
	# Check if all rounds for this difficulty are completed
	if round_number >= max_rounds:
		# Mark current difficulty as completed
		if difficulty not in completed_difficulties:
			completed_difficulties.append(difficulty)
		print("Difficulty ", difficulty, " completed!")
		show_difficulty_complete_popup()
	else:
		# More rounds in this difficulty
		print("Round ", round_number, " of ", max_rounds, " completed")
		show_round_complete_popup()

func show_round_complete_popup():
	if not results_label or not round_complete_popup:
		return
	
	var max_rounds = difficulty_settings[difficulty].rounds
	
	results_label.text = "[center]🎉 Round " + str(round_number) + " Complete! 🎉[/center]\n\n"
	results_label.text += "You successfully counted from 1 to " + str(target_number) + "!\n\n"
	results_label.text += "[b]Difficulty:[/b] " + difficulty.capitalize() + "\n"
	results_label.text += "[b]Round:[/b] " + str(round_number) + "/" + str(max_rounds) + "\n"
	results_label.text += "[b]Numbers Clicked:[/b] " + str(target_number) + "/" + str(target_number) + "\n\n"
	results_label.text += "Ready for round " + str(round_number + 1) + "?"
	
	next_round_button.text = "Next Round"
	round_complete_popup.popup_centered()

func show_difficulty_complete_popup():
	if not results_label or not round_complete_popup:
		return
	
	var current_difficulty_index = difficulty_order.find(difficulty)
	var next_difficulty_available = current_difficulty_index < difficulty_order.size() - 1
	var max_rounds = difficulty_settings[difficulty].rounds
	
	# Build popup message
	results_label.text = "[center]🏆 " + difficulty.capitalize() + " Mastered! 🏆[/center]\n\n"
	results_label.text += "Amazing! You completed all " + str(max_rounds) + " rounds!\n\n"
	results_label.text += "[b]Difficulty:[/b] " + difficulty.capitalize() + " ✓\n"
	results_label.text += "[b]Rounds Completed:[/b] " + str(max_rounds) + "/" + str(max_rounds) + "\n\n"
	
	# Update button text based on progression
	if next_difficulty_available:
		var next_difficulty = difficulty_order[current_difficulty_index + 1]
		var next_rounds = difficulty_settings[next_difficulty].rounds
		next_round_button.text = "Try " + next_difficulty.capitalize()
		finish_button.text = "Main Menu"
		results_label.text += "[b]Next Challenge:[/b] " + next_difficulty.capitalize() + "\n"
		results_label.text += "(" + str(next_rounds) + " rounds, " + difficulty_settings[next_difficulty].description + ")\n\n"
		results_label.text += "Ready for the next challenge?"
	else:
		# All difficulties completed
		next_round_button.text = "Play Again"
		finish_button.text = "Main Menu"
		results_label.text += "[b][color=gold]🎖️ CHAMPION! 🎖️[/color][/b]\n"
		results_label.text += "You've mastered ALL difficulties!\n"
		results_label.text += "• Easy: 3 rounds ✓\n"
		results_label.text += "• Medium: 4 rounds ✓\n"
		results_label.text += "• Hard: 5 rounds ✓\n\n"
		results_label.text += "[b]Total: 12 rounds completed![/b]"
	
	round_complete_popup.popup_centered()

func show_completion_popup():
	# This function is now replaced by show_round_complete_popup and show_difficulty_complete_popup
	pass

func update_math_sprite_expression(expression: String):
	match expression:
		"neutral":
			if math_sprite:
				math_sprite.modulate = Color.WHITE
		"happy":
			if math_sprite:
				math_sprite.modulate = Color.LIGHT_GREEN
		"sad":
			if math_sprite:
				math_sprite.modulate = Color.LIGHT_PINK
		"excited":
			if math_sprite:
				math_sprite.modulate = Color.YELLOW

func connect_buttons():
	print("Connecting buttons...")
	
	# Connect main menu buttons
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		print("Start button connected")
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Connect difficulty buttons
	if easy_button:
		easy_button.pressed.connect(_on_difficulty_selected.bind("easy"))
	if medium_button:
		medium_button.pressed.connect(_on_difficulty_selected.bind("medium"))
	if hard_button:
		hard_button.pressed.connect(_on_difficulty_selected.bind("hard"))
	
	# Connect popup buttons
	if next_round_button:
		next_round_button.pressed.connect(_on_next_round_pressed)
	if finish_button:
		finish_button.pressed.connect(_on_finish_game_pressed)
	
	# Initialize difficulty button texts
	update_difficulty_button_texts()

# Button handlers
func _on_start_button_pressed():
	print("Start button pressed")
	start_game()

func _on_options_button_pressed():
	print("Options button pressed")
	if difficulty_popup:
		difficulty_popup.popup_centered()

func _on_back_button_pressed():
	print("Back button pressed - returning to shape match game")
	# Navigate back to the shape match game
	get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")

func _on_reset_button_pressed():
	print("Reset button pressed")
	if game_active:
		generate_new_round()
	else:
		# Show options for reset button when not in active game
		show_main_menu_options()

func show_main_menu_options():
	# Create a simple popup with options
	var options_dialog = AcceptDialog.new()
	options_dialog.title = "🎮 Game Options"
	options_dialog.dialog_text = "What would you like to do?"
	
	# Create container for buttons
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	
	# Reset Game button
	var reset_game_btn = Button.new()
	reset_game_btn.text = "🔄 Reset Counting Game"
	reset_game_btn.custom_minimum_size = Vector2(250, 40)
	reset_game_btn.pressed.connect(func(): 
		options_dialog.queue_free()
		return_to_main_menu()
	)
	
	# Back to Shape Match button  
	var back_shape_btn = Button.new()
	back_shape_btn.text = "🔙 Back to Shape Match"
	back_shape_btn.custom_minimum_size = Vector2(250, 40)
	back_shape_btn.pressed.connect(func(): 
		options_dialog.queue_free()
		get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")
	)
	
	# Main Menu button
	var main_menu_btn = Button.new()
	main_menu_btn.text = "🏠 Main Menu (Play All Games)"
	main_menu_btn.custom_minimum_size = Vector2(250, 40)
	main_menu_btn.pressed.connect(func(): 
		options_dialog.queue_free()
		get_tree().change_scene_to_file("res://Scenes/1 MainMenu.tscn")
	)
	
	# Style buttons
	for btn in [reset_game_btn, back_shape_btn, main_menu_btn]:
		btn.add_theme_color_override("font_color", Color.BLACK)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color.WHITE
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color.BLUE
		btn_style.corner_radius_top_left = 15
		btn_style.corner_radius_top_right = 15
		btn_style.corner_radius_bottom_left = 15
		btn_style.corner_radius_bottom_right = 15
		btn.add_theme_stylebox_override("normal", btn_style)
	
	# Add buttons to container
	button_container.add_child(reset_game_btn)
	button_container.add_child(back_shape_btn)
	button_container.add_child(main_menu_btn)
	
	# Add container to dialog
	options_dialog.add_child(button_container)
	
	# Add to scene and show
	add_child(options_dialog)
	options_dialog.popup_centered()

func _on_difficulty_selected(selected_difficulty: String):
	set_difficulty(selected_difficulty)
	if difficulty_popup:
		difficulty_popup.hide()
	print("Difficulty set to: ", selected_difficulty)
	
	# Reset game state for new difficulty
	round_number = 1
	current_count = 1
	completed_difficulties = []
	
	# If game is currently active, restart with new difficulty
	if game_active and game_started:
		# Keep game active but regenerate with new difficulty
		generate_new_round()
		print("Active game updated to ", selected_difficulty, " difficulty")
	else:
		# Game is not active, just update the preview
		generate_initial_display()
		print("Preview updated to ", selected_difficulty, " difficulty")

func _on_next_round_pressed():
	if round_complete_popup:
		round_complete_popup.hide()
	
	var max_rounds = difficulty_settings[difficulty].rounds
	var current_difficulty_index = difficulty_order.find(difficulty)
	
	# Check if we're still in the same difficulty (more rounds to go)
	if round_number < max_rounds:
		# Continue to next round in same difficulty
		round_number += 1
		
		# Generate new target number for this round
		var range_data = difficulty_settings[difficulty]
		target_number = randi_range(range_data.min, range_data.max)
		
		# Reactivate the game for next round
		game_started = true
		game_active = true
		
		generate_new_round()
		print("Starting round ", round_number, " of ", max_rounds, " in ", difficulty)
		
	elif current_difficulty_index < difficulty_order.size() - 1:
		# Move to next difficulty (all rounds of current difficulty completed)
		var next_difficulty = difficulty_order[current_difficulty_index + 1]
		set_difficulty(next_difficulty)
		round_number = 1  # Reset round number for new difficulty
		
		# Reactivate the game for next difficulty
		game_started = true
		game_active = true
		
		generate_new_round()
		print("Moving to next difficulty: ", next_difficulty, " - Round 1")
	else:
		# All difficulties completed, restart from easy
		completed_difficulties.clear()
		set_difficulty("easy")
		round_number = 1
		
		# Reactivate the game for restart
		game_started = true
		game_active = true
		
		generate_new_round()
		print("All difficulties completed, restarting from easy")

func _on_finish_game_pressed():
	if round_complete_popup:
		round_complete_popup.hide()
	print("Finish button pressed - going to main menu")
	# Navigate to main menu to play all games
	get_tree().change_scene_to_file("res://Scenes/1 MainMenu.tscn")

func return_to_main_menu():
	print("Returning to main menu...")
	game_active = false
	game_started = false
	
	# Don't hide anything, just disable the game buttons
	for button in buttons_array:
		button.disabled = true
		# Style disabled buttons
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color.LIGHT_GRAY
		disabled_style.border_width_left = 2
		disabled_style.border_width_top = 2
		disabled_style.border_width_right = 2
		disabled_style.border_width_bottom = 2
		disabled_style.border_color = Color.GRAY
		disabled_style.corner_radius_top_left = 15
		disabled_style.corner_radius_top_right = 15
		disabled_style.corner_radius_bottom_left = 15
		disabled_style.corner_radius_bottom_right = 15
		button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Reset game state
	round_number = 1
	current_count = 1
	correct_answers = 0
	
	# Clear feedback and show start message
	show_feedback("Click Start Game to begin!", 0.0)
	
	# Reset math sprite
	update_math_sprite_expression("neutral")
	
	# Reset to easy difficulty
	set_difficulty("easy")
	generate_initial_display()

# Public functions that can be called from other scripts
func start_game_with_difficulty(new_difficulty: String):
	set_difficulty(new_difficulty)
	start_game()

func reset_game():
	if game_active:
		generate_new_round()
	else:
		return_to_main_menu()

func get_current_progress():
	return {"current": current_count - 1, "target": target_number, "round": round_number, "difficulty": difficulty}

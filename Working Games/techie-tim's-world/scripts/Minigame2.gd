extends Control

# Node references
@onready var robot_container = $MainContainer/GameContent/LeftPanel/RobotContainer
@onready var robot_face = $MainContainer/GameContent/LeftPanel/RobotContainer/RobotContent/RobotFace
@onready var error_message = $MainContainer/GameContent/LeftPanel/RobotContainer/RobotContent/ErrorMessage
@onready var scrambled_display = $MainContainer/GameContent/LeftPanel/RobotContainer/RobotContent/ScrambledDisplay

# Drop zones
@onready var drop_zone1 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone1
@onready var drop_zone2 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone2
@onready var drop_zone3 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone3
@onready var drop_label1 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone1/DropLabel1
@onready var drop_label2 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone2/DropLabel2
@onready var drop_label3 = $MainContainer/GameContent/LeftPanel/FixZone/DropZoneContainer/DropZone3/DropLabel3

# UI elements
@onready var word_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/WordLabel
@onready var score_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/ScoreLabel
@onready var status_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/StatusLabel
@onready var fix_label = $MainContainer/GameContent/LeftPanel/FixZone/FixLabel

# Control buttons
@onready var test_button = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/ControlButtons/TestRobotButton
@onready var next_button = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/ControlButtons/NextWordButton
@onready var reset_button = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/ControlButtons/ResetButton
@onready var main_menu_button = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/ControlButtons/MainMenuButton
@onready var game_select_button = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/ControlButtons/GameSelectButton

# Game variables
var current_word_index = 0
var robots_fixed = 0
var selected_letter = ""
var robot_fixed = false
var attempt_count = 0
var correct_positions = []

# Word data with hints and encouragement
var word_data = [
	{
		"target": "CAT", 
		"scrambled": "TAC", 
		"letters": ["C", "A", "T"],
		"hint": "This pet says MEOW",
		"sound_hint": "Listen: C-A-T makes the word CAT"
	},
	{
		"target": "DOG", 
		"scrambled": "GOD", 
		"letters": ["D", "O", "G"],
		"hint": "This pet says WOOF",
		"sound_hint": "Listen: D-O-G makes the word DOG"
	},
	{
		"target": "BAT", 
		"scrambled": "TAB", 
		"letters": ["B", "A", "T"],
		"hint": "This animal can fly",
		"sound_hint": "Listen: B-A-T makes the word BAT"
	},
	{
		"target": "SUN", 
		"scrambled": "NUS", 
		"letters": ["S", "U", "N"],
		"hint": "This is bright in the sky",
		"sound_hint": "Listen: S-U-N makes the word SUN"
	},
	{
		"target": "RUN", 
		"scrambled": "NUR", 
		"letters": ["R", "U", "N"],
		"hint": "We do this with our legs fast",
		"sound_hint": "Listen: R-U-N makes the word RUN"
	}
]

# Drop zone arrays
var drop_zones = []
var drop_labels = []
var solution_sequence = []
var player_sequence = []

# Accessibility features
var voice_feedback_enabled = true
var celebration_count = 0

func _ready():
	print("Debug the Word Bot - Accessible Version Starting!")
	
	fix_label.text = "CLICK LETTERS TO FIX THE ROBOT:"
	
	drop_zones = [drop_zone1, drop_zone2, drop_zone3]
	drop_labels = [drop_label1, drop_label2, drop_label3]
	
	setup_drop_zones()
	load_current_word()
	connect_signals()
	update_ui()

func setup_drop_zones():
	for i in range(drop_zones.size()):
		var zone = drop_zones[i]
		var zone_button = Button.new()
		zone_button.flat = true
		zone_button.custom_minimum_size = zone.size
		zone_button.position = Vector2.ZERO
		zone_button.size = zone.size
		zone_button.pressed.connect(_on_drop_zone_clicked.bind(i))
		zone.add_child(zone_button)

func connect_signals():
	test_button.pressed.connect(_on_test_robot_pressed)
	next_button.pressed.connect(_on_next_word_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	game_select_button.pressed.connect(_on_game_select_pressed)

func load_current_word():
	if current_word_index >= word_data.size():
		show_completion()
		return
	
	var word_info = word_data[current_word_index]
	solution_sequence = word_info.letters.duplicate()
	player_sequence = ["", "", ""]
	robot_fixed = false
	attempt_count = 0
	correct_positions = [false, false, false]
	
	# Update UI with bigger, clearer text
	word_label.text = "HELP THE ROBOT SAY: " + word_info.target
	scrambled_display.text = word_info.scrambled
	
	# Reset robot to broken state - keeping original robot emoji
	robot_face.text = "🤖"
	robot_face.modulate = Color(1, 0.3, 0.3, 1)
	error_message.text = "The robot is mixed up! Can you help?"
	error_message.modulate = Color(1, 0.4, 0.4, 1)
	
	# Reset drop zones with clearer visual cues
	for i in range(drop_labels.size()):
		drop_labels[i].text = str(i + 1)  # Show position numbers
		drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
	
	update_letter_buttons(word_info.letters)
	selected_letter = ""
	
	# Clear, encouraging instructions
	status_label.text = "Click any letter below to start helping the robot!"
	
	# Give initial hint after a moment
	await get_tree().create_timer(2.0).timeout
	if attempt_count == 0:  # Only if they haven't started yet
		show_helpful_hint("start")
	
	update_ui()

func update_letter_buttons(available_letters: Array):
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	
	# Clear existing buttons
	for child in letter_grid.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Shuffle letters but keep them predictable for learning
	var shuffled_letters = available_letters.duplicate()
	shuffled_letters.shuffle()
	
	# Create bigger, more accessible letter buttons
	for i in range(shuffled_letters.size()):
		var letter = shuffled_letters[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(80, 80)  # Bigger for easier clicking
		button.text = letter
		button.add_theme_font_size_override("font_size", 36)  # Larger text
		button.add_theme_color_override("font_color", Color.WHITE)
		
		# High contrast styles for better visibility
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.1, 0.3, 0.8, 1)  # More contrast
		normal_style.border_width_left = 4
		normal_style.border_width_top = 4
		normal_style.border_width_right = 4
		normal_style.border_width_bottom = 4
		normal_style.border_color = Color(0.3, 0.5, 1, 1)
		normal_style.corner_radius_top_left = 20
		normal_style.corner_radius_top_right = 20
		normal_style.corner_radius_bottom_right = 20
		normal_style.corner_radius_bottom_left = 20
		button.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.2, 0.4, 1, 1)
		hover_style.border_color = Color(0.4, 0.6, 1, 1)
		button.add_theme_stylebox_override("hover", hover_style)
		
		button.pressed.connect(_on_letter_selected.bind(letter))
		letter_grid.add_child(button)

func _on_letter_selected(letter: String):
	selected_letter = letter
	
	# Positive, encouraging feedback
	var encouraging_messages = [
		"Great choice! Now click a box to place " + letter,
		"Perfect! Click any empty box for " + letter,
		"You picked " + letter + "! Click a box to put it there",
		"Nice! Click a numbered box to place " + letter
	]
	
	status_label.text = encouraging_messages[randi() % encouraging_messages.size()]
	
	# Visual feedback - highlight selected letter more gently
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	for child in letter_grid.get_children():
		if child is Button:
			if child.text == letter:
				child.modulate = Color(1.3, 1.3, 1.3, 1)
				# Gentle pulsing animation
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(child, "modulate", Color(1.5, 1.5, 1.2, 1), 0.8)
				tween.tween_property(child, "modulate", Color(1.3, 1.3, 1.3, 1), 0.8)
			else:
				child.modulate = Color(0.7, 0.7, 0.7, 1)  # Dim but not too much
	
	# After 3 seconds of inactivity, give a gentle reminder
	await get_tree().create_timer(3.0).timeout
	if selected_letter == letter:  # Still selected
		status_label.text = "Remember: Click a numbered box to place " + letter

func _on_drop_zone_clicked(zone_index: int):
	# If slot is filled, make removal friendly
	if player_sequence[zone_index] != "":
		var removed_letter = player_sequence[zone_index]
		player_sequence[zone_index] = ""
		drop_labels[zone_index].text = str(zone_index + 1)
		drop_labels[zone_index].modulate = Color(0.8, 0.8, 1, 1)
		
		var removal_messages = [
			removed_letter + " is back! Try a different letter here",
			"OK! " + removed_letter + " is removed. What letter goes here?",
			"Good! Now try another letter in box " + str(zone_index + 1)
		]
		status_label.text = removal_messages[randi() % removal_messages.size()]
		
		test_button.modulate = Color(1, 1, 1, 1)
		return
	
	if selected_letter == "":
		# Gentle guidance without criticism
		var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
		for child in letter_grid.get_children():
			if child is Button:
				child.modulate = Color(1.2, 1.2, 0.8, 1)  # Soft yellow highlight
		
		status_label.text = "First click a letter, then click this box!"
		
		# Reset highlight gently
		await get_tree().create_timer(2.5).timeout
		for child in letter_grid.get_children():
			if child is Button:
				child.modulate = Color(1, 1, 1, 1)
		return
	
	# Place letter with celebration
	player_sequence[zone_index] = selected_letter
	drop_labels[zone_index].text = selected_letter
	drop_labels[zone_index].modulate = Color(0.2, 1, 0.4, 1)  # Bright green for success
	
	# Celebration animation
	var tween = create_tween()
	tween.tween_property(drop_labels[zone_index], "scale", Vector2(1.4, 1.4), 0.3)
	tween.tween_property(drop_labels[zone_index], "scale", Vector2(1.0, 1.0), 0.3)
	
	# Immediate positive reinforcement
	var placement_celebrations = [
		"Wonderful! " + selected_letter + " is in place!",
		"Great job placing " + selected_letter + "!",
		"Perfect! " + selected_letter + " looks good there!",
		"You did it! " + selected_letter + " is placed!"
	]
	status_label.text = placement_celebrations[randi() % placement_celebrations.size()]
	
	selected_letter = ""
	
	# Reset button highlights gently
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	for child in letter_grid.get_children():
		if child is Button:
			child.modulate = Color(1, 1, 1, 1)
	
	# Check progress and give appropriate encouragement
	var filled_slots = 0
	for seq in player_sequence:
		if seq != "":
			filled_slots += 1
	
	await get_tree().create_timer(1.5).timeout  # Let them enjoy the success
	
	if filled_slots == 1:
		status_label.text = "Great start! Pick another letter to continue."
	elif filled_slots == 2:
		status_label.text = "Almost done! One more letter to go!"
	elif filled_slots == 3:
		status_label.text = "All done! Click TEST ROBOT to see if you helped!"
		
		# Make test button more inviting
		test_button.modulate = Color(0.8, 1.2, 0.8, 1)  # Gentle green glow
		var test_tween = create_tween()
		test_tween.set_loops()
		test_tween.tween_property(test_button, "modulate", Color(0.9, 1.3, 0.9, 1), 1.0)
		test_tween.tween_property(test_button, "modulate", Color(0.8, 1.2, 0.8, 1), 1.0)

func _on_test_robot_pressed():
	test_button.modulate = Color(1, 1, 1, 1)
	attempt_count += 1
	
	# Check if all slots are filled
	var all_filled = true
	for letter in player_sequence:
		if letter == "":
			all_filled = false
			break
	
	if not all_filled:
		status_label.text = "You need to fill all the boxes first! You're doing great!"
		
		# Gently highlight empty slots without stress
		for i in range(player_sequence.size()):
			if player_sequence[i] == "":
				drop_labels[i].modulate = Color(1, 1, 0.6, 1)  # Gentle yellow
				var tween = create_tween()
				tween.set_loops(2)
				tween.tween_property(drop_labels[i], "scale", Vector2(1.1, 1.1), 0.4)
				tween.tween_property(drop_labels[i], "scale", Vector2(1.0, 1.0), 0.4)
		
		await get_tree().create_timer(2.0).timeout
		for i in range(drop_labels.size()):
			if player_sequence[i] == "":
				drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
		return
	
	# Testing sequence with anticipation
	status_label.text = "Testing... Let's see if you helped the robot!"
	
	for i in range(3):
		status_label.text = "Testing" + ".".repeat(i + 1)
		await get_tree().create_timer(0.4).timeout
	
	# Check correctness with detailed feedback
	var correct_count = 0
	var position_feedback = []
	
	for i in range(solution_sequence.size()):
		if i < player_sequence.size() and player_sequence[i] == solution_sequence[i]:
			correct_count += 1
			correct_positions[i] = true
			position_feedback.append("Position " + str(i + 1) + ": Perfect!")
			# Keep the green color for correct positions
			drop_labels[i].modulate = Color(0.2, 1, 0.4, 1)
		else:
			correct_positions[i] = false
			position_feedback.append("Position " + str(i + 1) + ": Try again")
			# Gentle orange for incorrect - not scary red
			drop_labels[i].modulate = Color(1, 0.8, 0.4, 1)
	
	if correct_count == solution_sequence.size():
		fix_robot()
	else:
		show_encouraging_failure(correct_count)

func fix_robot():
	robot_fixed = true
	robots_fixed += 1
	celebration_count += 1
	
	# Happy robot appearance - keeping original robot emoji
	robot_face.text = "🤖"
	robot_face.modulate = Color(0.3, 1, 0.3, 1)
	error_message.text = "YAY! You helped me! Thank you!"
	error_message.modulate = Color(0.2, 1, 0.2, 1)
	scrambled_display.text = word_data[current_word_index].target
	scrambled_display.modulate = Color(0.2, 1, 0.2, 1)
	
	# Friendly green container
	var fixed_style = StyleBoxFlat.new()
	fixed_style.bg_color = Color(0.1, 0.2, 0.1, 0.95)
	fixed_style.border_width_left = 4
	fixed_style.border_width_top = 4
	fixed_style.border_width_right = 4
	fixed_style.border_width_bottom = 4
	fixed_style.border_color = Color(0.3, 1, 0.3, 1)
	fixed_style.corner_radius_top_left = 20
	fixed_style.corner_radius_top_right = 20
	fixed_style.corner_radius_bottom_right = 20
	fixed_style.corner_radius_bottom_left = 20
	fixed_style.shadow_color = Color(0.3, 1, 0.3, 0.3)
	fixed_style.shadow_size = 8
	robot_container.add_theme_stylebox_override("panel", fixed_style)
	
	# Celebration with variety based on how many they've completed
	var celebration_messages = [
		"AMAZING! You fixed the robot! You're so smart!",
		"WONDERFUL! The robot is happy now thanks to you!",
		"FANTASTIC! You're getting really good at this!",
		"INCREDIBLE! You're a robot helper superstar!"
	]
	
	if celebration_count <= 3:
		status_label.text = celebration_messages[min(celebration_count - 1, celebration_messages.size() - 1)]
	else:
		status_label.text = "WOW! You've helped " + str(celebration_count) + " robots! You're amazing!"
	
	# Gentle celebration animation
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(robot_face, "scale", Vector2(1.1, 1.1), 0.4)
	tween.tween_property(robot_face, "scale", Vector2(1.0, 1.0), 0.4)
	
	# Auto-advance with more time to enjoy success
	await get_tree().create_timer(3.0).timeout
	if current_word_index < word_data.size() - 1:
		_on_next_word_pressed()
	else:
		show_completion()

func show_encouraging_failure(correct_count: int):
	# Focus on what they got right, not wrong
	if correct_count > 0:
		var encouraging_messages = [
			"Good try! You got " + str(correct_count) + " right! Try moving the others.",
			"Great job! " + str(correct_count) + " letters are perfect! Keep going!",
			"You're doing well! " + str(correct_count) + " letters are in the right place!"
		]
		status_label.text = encouraging_messages[randi() % encouraging_messages.size()]
	else:
		status_label.text = "Good try! The robot is still learning. Want to try again?"
	
	await get_tree().create_timer(2.0).timeout
	
	# Offer help after multiple attempts
	if attempt_count >= 2:
		show_helpful_hint("attempt")
	
	await get_tree().create_timer(2.0).timeout
	
	# Reset incorrect positions to normal color, keep correct ones green
	for i in range(drop_labels.size()):
		if not correct_positions[i] and player_sequence[i] != "":
			drop_labels[i].modulate = Color(0.4, 1, 0.8, 1)
	
	status_label.text = "Try again! Click letters to move them around."

func show_helpful_hint(hint_type: String):
	var word_info = word_data[current_word_index]
	
	if hint_type == "start":
		status_label.text = "Hint: " + word_info.hint + ". Can you spell it?"
	elif hint_type == "attempt":
		if attempt_count == 2:
			status_label.text = "Hint: " + word_info.hint + ". The word is " + word_info.target + "."
		elif attempt_count >= 3:
			status_label.text = "Let me help! " + word_info.sound_hint
			# Also highlight the first correct position
			for i in range(solution_sequence.size()):
				if not correct_positions[i]:
					drop_labels[i].modulate = Color(1, 1, 0.3, 1)  # Yellow highlight for help
					await get_tree().create_timer(1.0).timeout
					drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
					break

func _on_next_word_pressed():
	# Check if this is "PLAY AGAIN" from completion screen
	if next_button.text == "🔄 PLAY AGAIN":
		restart_game()
		return
	
	if not robot_fixed:
		status_label.text = "Help fix this robot first! You can do it!"
		return
	
	current_word_index += 1
	load_current_word()

func restart_game():
	# Reset all game variables to starting state
	current_word_index = 0
	robots_fixed = 0
	attempt_count = 0
	correct_positions = [false, false, false]
	celebration_count = 0
	
	# Reset button texts back to normal
	next_button.text = "➡️ NEXT ROBOT"
	main_menu_button.text = "Next Game"
	game_select_button.text = "🎮 GAME SELECT"
	reset_button.visible = true
	
	# Load first word
	load_current_word()
	
	status_label.text = "Game restarted! Ready to help robots from the beginning."

func _on_reset_pressed():
	player_sequence = ["", "", ""]
	selected_letter = ""
	attempt_count = 0
	correct_positions = [false, false, false]
	
	# Reset drop zones
	for i in range(drop_labels.size()):
		drop_labels[i].text = str(i + 1)
		drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
	
	# Reset robot to friendly broken state
	var broken_style = StyleBoxFlat.new()
	broken_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	broken_style.border_width_left = 4
	broken_style.border_width_top = 4
	broken_style.border_width_right = 4
	broken_style.border_width_bottom = 4
	broken_style.border_color = Color(1, 0.6, 0.2, 1)
	broken_style.corner_radius_top_left = 20
	broken_style.corner_radius_top_right = 20
	broken_style.corner_radius_bottom_right = 20
	broken_style.corner_radius_bottom_left = 20
	broken_style.shadow_color = Color(1, 0.6, 0.2, 0.3)
	broken_style.shadow_size = 8
	robot_container.add_theme_stylebox_override("panel", broken_style)
	
	robot_face.modulate = Color(1, 0.7, 0.3, 1)
	error_message.text = "The robot is mixed up! Can you help?"
	error_message.modulate = Color(1, 0.8, 0.4, 1)
	scrambled_display.text = word_data[current_word_index].scrambled
	scrambled_display.modulate = Color(1, 0.6, 0.2, 1)
	
	robot_fixed = false
	update_ui()
	status_label.text = "Fresh start! Click a letter to begin helping again."

func show_completion():
	status_label.text = "YOU DID IT! You helped ALL the robots! You're a SUPERSTAR!"
	robot_face.text = "CHAMPION"
	robot_face.modulate = Color.GOLD
	error_message.text = "CONGRATULATIONS! You are amazing at helping!"
	error_message.modulate = Color.GOLD
	scrambled_display.text = "YOU WIN!"
	scrambled_display.modulate = Color.GOLD
	
	# Change control buttons to completion options
	next_button.text = "🔄 PLAY AGAIN"
	next_button.visible = true
	main_menu_button.text = "🏠 MAIN MENU"
	main_menu_button.visible = true
	game_select_button.text = "🎮 GAME SELECT"
	game_select_button.visible = true
	reset_button.visible = false  # Hide reset button at completion to prevent crash

func update_ui():
	score_label.text = "ROBOTS HELPED: " + str(robots_fixed)
	
	if robot_fixed:
		status_label.text = "Robot is happy! Ready for the next one?"
	elif selected_letter != "":
		status_label.text = "You picked " + selected_letter + "! Click a box to place it!"
	else:
		var filled_slots = 0
		for seq in player_sequence:
			if seq != "":
				filled_slots += 1
		
		if filled_slots == 0:
			status_label.text = "Click any letter below to start helping!"
		elif filled_slots == 3:
			status_label.text = "All boxes filled! Click TEST ROBOT to check!"
		else:
			status_label.text = "Great job! " + str(3 - filled_slots) + " more letters to go!"

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/minigame_3.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Enhanced keyboard input for accessibility
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				var zone_index = event.keycode - KEY_1
				if zone_index < drop_zones.size():
					_on_drop_zone_clicked(zone_index)
			KEY_SPACE, KEY_ENTER:
				_on_test_robot_pressed()
			KEY_N:
				_on_next_word_pressed()
			KEY_R:
				_on_reset_pressed()
			KEY_H:  # Help key
				show_helpful_hint("attempt")

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

# Letter buttons
@onready var letter_c = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid/LetterC
@onready var letter_a = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid/LetterA
@onready var letter_t = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid/LetterT

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
var current_drop_zone = 0
var robot_fixed = false

# Word data - target words and their scrambled versions
var word_data = [
	{"target": "CAT", "scrambled": "TAC", "letters": ["C", "A", "T"]},
	{"target": "DOG", "scrambled": "GOD", "letters": ["D", "O", "G"]},
	{"target": "BAT", "scrambled": "TAB", "letters": ["B", "A", "T"]},
	{"target": "SUN", "scrambled": "NUS", "letters": ["S", "U", "N"]},
	{"target": "RUN", "scrambled": "NUR", "letters": ["R", "U", "N"]},
	{"target": "BIG", "scrambled": "GIB", "letters": ["B", "I", "G"]},
	{"target": "RED", "scrambled": "DER", "letters": ["R", "E", "D"]},
	{"target": "BED", "scrambled": "DEB", "letters": ["B", "E", "D"]},
	{"target": "HAT", "scrambled": "TAH", "letters": ["H", "A", "T"]},
	{"target": "CAN", "scrambled": "NAC", "letters": ["C", "A", "N"]}
]

# Drop zone array for easy access
var drop_zones = []
var drop_labels = []

# Current word solution
var solution_sequence = []
var player_sequence = []

func _ready():
	print("🤖 Debug the Word Bot - Starting!")
	
	# Setup drop zones array
	drop_zones = [drop_zone1, drop_zone2, drop_zone3]
	drop_labels = [drop_label1, drop_label2, drop_label3]
	
	# Setup drop zone click detection
	setup_drop_zones()
	
	# Load first word
	load_current_word()
	
	# Connect signals
	connect_signals()
	
	# Initial UI update
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
	# Letter selection buttons
	letter_c.pressed.connect(_on_letter_selected.bind("C"))
	letter_a.pressed.connect(_on_letter_selected.bind("A"))
	letter_t.pressed.connect(_on_letter_selected.bind("T"))
	
	# Control buttons
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
	
	# Update UI
	word_label.text = "TARGET WORD: " + word_info.target
	scrambled_display.text = word_info.scrambled
	
	# Reset robot to broken state
	robot_face.text = "🤖"
	robot_face.modulate = Color(1, 0.3, 0.3, 1)
	error_message.text = "ERROR: WORD CIRCUITS SCRAMBLED!"
	error_message.modulate = Color(1, 0.4, 0.4, 1)
	
	# Reset drop zones
	for i in range(drop_labels.size()):
		drop_labels[i].text = "?"
		drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
	
	# Update available letters for current word
	update_letter_buttons(word_info.letters)
	
	# Reset UI
	current_drop_zone = 0
	selected_letter = ""
	
	# Clear and helpful instructions
	status_label.text = "Select a letter from the toolbox, then click a slot to place it!"
	
	update_ui()

func update_letter_buttons(available_letters: Array):
	# Get the letter grid container
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	
	# Clear existing buttons
	for child in letter_grid.get_children():
		child.queue_free()
	
	# Wait for nodes to be freed
	await get_tree().process_frame
	
	# SHUFFLE the letters so they're not in the correct order!
	var shuffled_letters = available_letters.duplicate()
	shuffled_letters.shuffle()
	
	# Create new letter buttons for current word (in shuffled order)
	for i in range(shuffled_letters.size()):
		var letter = shuffled_letters[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(70, 70)
		button.text = letter
		button.add_theme_font_size_override("font_size", 32)
		button.add_theme_color_override("font_color", Color.WHITE)
		
		# Apply styles (simplified version)
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.2, 0.8, 0.9)
		normal_style.border_width_left = 3
		normal_style.border_width_top = 3
		normal_style.border_width_right = 3
		normal_style.border_width_bottom = 3
		normal_style.border_color = Color(0.4, 0.4, 1, 1)
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_right = 15
		normal_style.corner_radius_bottom_left = 15
		button.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.3, 0.3, 1, 1)
		hover_style.border_color = Color(0.5, 0.5, 1, 1)
		button.add_theme_stylebox_override("hover", hover_style)
		
		button.pressed.connect(_on_letter_selected.bind(letter))
		letter_grid.add_child(button)

func _on_letter_selected(letter: String):
	selected_letter = letter
	
	# Clear, non-specific instructions that don't give away the answer
	var filled_slots = 0
	for seq in player_sequence:
		if seq != "":
			filled_slots += 1
	
	if filled_slots == 0:
		status_label.text = "Good! Now click any empty slot to place '" + letter + "'"
	elif filled_slots == 1:
		status_label.text = "Great! Click another empty slot to place '" + letter + "'"
	elif filled_slots == 2:
		status_label.text = "Perfect! Click the last empty slot to place '" + letter + "'"
	
	# Highlight selected letter button
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	for child in letter_grid.get_children():
		if child is Button:
			if child.text == letter:
				child.modulate = Color(1.2, 1.2, 1.2, 1)
				# Add a pulsing effect to show it's selected
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(child, "modulate", Color(1.5, 1.5, 1.5, 1), 0.5)
				tween.tween_property(child, "modulate", Color(1.2, 1.2, 1.2, 1), 0.5)
			else:
				child.modulate = Color(0.6, 0.6, 0.6, 1)  # Dim other buttons

func _on_drop_zone_clicked(zone_index: int):
	# If slot is filled, remove the letter (click to clear)
	if player_sequence[zone_index] != "":
		var removed_letter = player_sequence[zone_index]
		player_sequence[zone_index] = ""
		drop_labels[zone_index].text = "?"
		drop_labels[zone_index].modulate = Color(0.8, 0.8, 1, 1)
		
		status_label.text = "Letter '" + removed_letter + "' removed! Select a new letter to place here."
		
		# Reset test button highlight if it was highlighted
		test_button.modulate = Color(1, 1, 1, 1)
		return
	
	if selected_letter == "":
		# Highlight the letter buttons to guide user
		var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
		for child in letter_grid.get_children():
			if child is Button:
				child.modulate = Color(1.3, 1.3, 0.5, 1)  # Yellow highlight
		
		status_label.text = "⚠️ First select a letter from the toolbox below!"
		
		# Reset highlight after 2 seconds
		await get_tree().create_timer(2.0).timeout
		for child in letter_grid.get_children():
			if child is Button:
				child.modulate = Color(1, 1, 1, 1)
		return
	
	# Place letter in the selected zone
	player_sequence[zone_index] = selected_letter
	drop_labels[zone_index].text = selected_letter
	drop_labels[zone_index].modulate = Color(0.4, 1, 0.8, 1)
	
	# Animation for placing letter
	var tween = create_tween()
	tween.tween_property(drop_labels[zone_index], "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(drop_labels[zone_index], "scale", Vector2(1.0, 1.0), 0.2)
	
	# Clear selection
	selected_letter = ""
	
	# Reset button highlights
	var letter_grid = $MainContainer/GameContent/RightPanel/LetterToolbox/ToolboxContainer/LetterGrid
	for child in letter_grid.get_children():
		if child is Button:
			child.modulate = Color(1, 1, 1, 1)
	
	# Check progress and give clear next steps
	var filled_slots = 0
	for seq in player_sequence:
		if seq != "":
			filled_slots += 1
	
	if filled_slots == 1:
		status_label.text = "Nice! Select another letter and place it in an empty slot."
	elif filled_slots == 2:
		status_label.text = "Almost there! Select the last letter and place it."
	elif filled_slots == 3:
		status_label.text = "ALL SLOTS FILLED! Click 'TEST ROBOT' to debug it! 🤖"
		# Highlight test button
		test_button.modulate = Color(1.3, 1.3, 0.5, 1)
		var test_tween = create_tween()
		test_tween.set_loops()
		test_tween.tween_property(test_button, "modulate", Color(1.5, 1.5, 0.7, 1), 0.6)
		test_tween.tween_property(test_button, "modulate", Color(1.3, 1.3, 0.5, 1), 0.6)

func _on_test_robot_pressed():
	# Reset test button highlight
	test_button.modulate = Color(1, 1, 1, 1)
	
	# Check if all slots are filled
	var all_filled = true
	for letter in player_sequence:
		if letter == "":
			all_filled = false
			break
	
	if not all_filled:
		status_label.text = "⚠️ FILL ALL 3 SLOTS before testing the robot!"
		
		# Highlight empty slots
		for i in range(player_sequence.size()):
			if player_sequence[i] == "":
				drop_labels[i].modulate = Color(1, 0.5, 0.5, 1)  # Red highlight
				var tween = create_tween()
				tween.set_loops(3)
				tween.tween_property(drop_labels[i], "scale", Vector2(1.2, 1.2), 0.3)
				tween.tween_property(drop_labels[i], "scale", Vector2(1.0, 1.0), 0.3)
		
		await get_tree().create_timer(2.0).timeout
		# Reset highlights
		for i in range(drop_labels.size()):
			if player_sequence[i] == "":
				drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
		return
	
	# Add suspense before showing result
	status_label.text = "🔍 TESTING ROBOT... ANALYZING CIRCUITS..."
	
	# Brief loading animation
	for i in range(3):
		status_label.text = "🔍 TESTING ROBOT" + ".".repeat(i + 1)
		await get_tree().create_timer(0.5).timeout
	
	# Check if sequence is correct
	var is_correct = true
	for i in range(solution_sequence.size()):
		if i < player_sequence.size() and player_sequence[i] != solution_sequence[i]:
			is_correct = false
			break
	
	if is_correct:
		fix_robot()
	else:
		show_debug_failure()

func fix_robot():
	robot_fixed = true
	robots_fixed += 1
	
	# Update robot appearance to fixed
	robot_face.text = "🤖"
	robot_face.modulate = Color(0.3, 1, 0.3, 1)
	error_message.text = "ROBOT ONLINE - WORD CIRCUITS FUNCTIONAL!"
	error_message.modulate = Color(0.3, 1, 0.3, 1)
	scrambled_display.text = word_data[current_word_index].target
	scrambled_display.modulate = Color(0.3, 1, 0.3, 1)
	
	# Change robot container style to green
	var fixed_style = StyleBoxFlat.new()
	fixed_style.bg_color = Color(0.05, 0.15, 0.05, 0.95)
	fixed_style.border_width_left = 4
	fixed_style.border_width_top = 4
	fixed_style.border_width_right = 4
	fixed_style.border_width_bottom = 4
	fixed_style.border_color = Color(0.2, 1, 0.2, 1)
	fixed_style.corner_radius_top_left = 20
	fixed_style.corner_radius_top_right = 20
	fixed_style.corner_radius_bottom_right = 20
	fixed_style.corner_radius_bottom_left = 20
	fixed_style.shadow_color = Color(0.2, 1, 0.2, 0.3)
	fixed_style.shadow_size = 8
	robot_container.add_theme_stylebox_override("panel", fixed_style)
	
	# Celebration animation
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(robot_face, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(robot_face, "scale", Vector2(1.0, 1.0), 0.3)
	
	status_label.text = "🎉 ROBOT FIXED! Word debugged successfully! 🎉"
	
	# Auto-advance after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if current_word_index < word_data.size() - 1:
		_on_next_word_pressed()
	else:
		show_completion()

func show_debug_failure():
	status_label.text = "❌ DEBUG FAILED! The robot is still glitching..."
	
	# Show what went wrong with detailed feedback
	await get_tree().create_timer(1.0).timeout
	
	var feedback = "🔍 DEBUGGING REPORT:\n"
	var correct_word = word_data[current_word_index].target
	var your_word = ""
	for letter in player_sequence:
		your_word += letter
	
	feedback += "• Target: " + correct_word + "\n"
	feedback += "• Your attempt: " + your_word + "\n"
	feedback += "• Try rearranging the letters!"
	
	status_label.text = feedback
	
	# Flash incorrect positions red
	for i in range(player_sequence.size()):
		if i < solution_sequence.size() and player_sequence[i] != solution_sequence[i]:
			drop_labels[i].modulate = Color(1, 0.3, 0.3, 1)
	
	await get_tree().create_timer(2.0).timeout
	
	# Reset to normal color but keep letters
	for i in range(drop_labels.size()):
		if player_sequence[i] != "":
			drop_labels[i].modulate = Color(0.4, 1, 0.8, 1)
	
	status_label.text = "Try again! Click letters to remove them, or reset to start over."

func _on_next_word_pressed():
	if not robot_fixed:
		status_label.text = "Fix the current robot first!"
		return
	
	current_word_index += 1
	load_current_word()

func _on_reset_pressed():
	# Reset current word
	player_sequence = ["", "", ""]
	selected_letter = ""
	
	# Reset drop zones
	for i in range(drop_labels.size()):
		drop_labels[i].text = "?"
		drop_labels[i].modulate = Color(0.8, 0.8, 1, 1)
	
	# Reset robot to broken state
	var broken_style = StyleBoxFlat.new()
	broken_style.bg_color = Color(0.05, 0.05, 0.15, 0.95)
	broken_style.border_width_left = 4
	broken_style.border_width_top = 4
	broken_style.border_width_right = 4
	broken_style.border_width_bottom = 4
	broken_style.border_color = Color(1, 0.2, 0.2, 1)
	broken_style.corner_radius_top_left = 20
	broken_style.corner_radius_top_right = 20
	broken_style.corner_radius_bottom_right = 20
	broken_style.corner_radius_bottom_left = 20
	broken_style.shadow_color = Color(1, 0.2, 0.2, 0.3)
	broken_style.shadow_size = 8
	robot_container.add_theme_stylebox_override("panel", broken_style)
	
	robot_face.modulate = Color(1, 0.3, 0.3, 1)
	error_message.text = "ERROR: WORD CIRCUITS SCRAMBLED!"
	error_message.modulate = Color(1, 0.4, 0.4, 1)
	scrambled_display.text = word_data[current_word_index].scrambled
	scrambled_display.modulate = Color(1, 0.2, 0.2, 1)
	
	robot_fixed = false
	update_ui()
	status_label.text = "Robot reset! Try debugging it again."

func show_completion():
	status_label.text = "🏆 ALL ROBOTS FIXED! You're a debugging master! 🏆"
	robot_face.text = "🏆"
	robot_face.modulate = Color.GOLD
	error_message.text = "CONGRATULATIONS - ALL SYSTEMS OPERATIONAL!"
	error_message.modulate = Color.GOLD
	scrambled_display.text = "MISSION COMPLETE!"
	scrambled_display.modulate = Color.GOLD

func update_ui():
	score_label.text = "ROBOTS FIXED: " + str(robots_fixed)
	
	if robot_fixed:
		status_label.text = "✅ Robot fixed! Ready for next challenge."
	elif selected_letter != "":
		status_label.text = "Selected: " + selected_letter + " - Click a slot to place it!"
	else:
		var filled_slots = 0
		for seq in player_sequence:
			if seq != "":
				filled_slots += 1
		
		if filled_slots == 0:
			status_label.text = "Click a letter below to start debugging!"
		elif filled_slots == 3:
			status_label.text = "All slots filled! Click 'TEST ROBOT' button!"
		else:
			status_label.text = "Continue filling slots... " + str(3 - filled_slots) + " more needed!"

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/minigame_3.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Keyboard input for accessibility
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

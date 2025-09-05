extends Control

# Word Sort Game for Children with Learning Disabilities
# Sorts Kindergarten sight words into categories

# Game state variables
var game_active = false
var current_words = []
var sorted_words = {}
var current_level = 1
var score = 0

# Audio player
var word_audio: AudioStreamPlayer

# UI References - will be set in _ready()
var word_sort_panel: Panel
var instructions_panel: Panel
var main_menu_btn: Button
var game_selection_btn: Button
var settings_btn: Button

# Drag variables
var dragging_item = null
var drag_offset = Vector2()

# Word categories for sorting
var word_categories = {
	"level_1": {
		"title": "Sort by Word Length",
		"categories": {
			"Short Words (2-3 letters)": ["I", "a", "go", "to", "up", "in", "at", "am", "it", "no", "by", "of", "us", "be", "on", "we", "he", "my", "me"],
			"Long Words (4+ letters)": ["like", "have", "play", "come", "this", "said", "look", "with", "they", "your", "from", "went", "jump"]
		}
	},
	"level_2": {
		"title": "Sort by Actions vs Things",
		"categories": {
			"Action Words": ["go", "play", "come", "look", "jump", "run", "see", "get", "came", "went"],
			"Thing Words": ["day", "way", "car", "dog", "cat", "tree", "book", "home", "door", "food"]
		}
	},
	"level_3": {
		"title": "Sort by Colors vs Numbers", 
		"categories": {
			"Colors": ["red", "blue", "green", "yellow", "black", "white", "brown", "purple", "pink"],
			"Numbers": ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
		}
	}
}

# Drop zones
var drop_zones = []

func _ready():
	# Initialize node references safely
	call_deferred("initialize_nodes")

func initialize_nodes():
	# Get node references with error checking - matching your scene structure
	word_sort_panel = get_node_or_null("Panel/VBoxContainer/Panel")
	instructions_panel = get_node_or_null("Panel/VBoxContainer3/Panel2")  # Changed from Panel to Panel2
	main_menu_btn = get_node_or_null("Panel/VBoxContainer3/VBoxContainer/StartButton")
	game_selection_btn = get_node_or_null("Panel/VBoxContainer3/VBoxContainer/InstructionButton")
	settings_btn = get_node_or_null("Panel/VBoxContainer3/VBoxContainer/SettingButton")
	
	# Check if nodes were found
	if not word_sort_panel:
		print("Warning: word_sort_panel not found")
	if not instructions_panel:
		print("Warning: instructions_panel not found")
	if not main_menu_btn:
		print("Warning: main_menu_btn not found")
	if not game_selection_btn:
		print("Warning: game_selection_btn not found")
	if not settings_btn:
		print("Warning: settings_btn not found")
	
	# Initialize components
	setup_audio_player()
	setup_instructions()
	connect_navigation_buttons()
	create_start_button()

func setup_audio_player():
	word_audio = AudioStreamPlayer.new()
	word_audio.name = "WordAudioPlayer"
	add_child(word_audio)
	print("AudioStreamPlayer created: ", word_audio.name)
	print("AudioStreamPlayer is valid: ", word_audio != null)

func setup_instructions():
	if not instructions_panel:
		print("Cannot setup instructions: panel not found")
		return
	
	# Clear existing content
	for child in instructions_panel.get_children():
		if child.name == "VBoxContainer":
			continue
		child.queue_free()
	
	# Create instruction container
	var instruction_container = VBoxContainer.new()
	instruction_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_container.add_theme_constant_override("separation", 8)
	instruction_container.position = Vector2(10, 10)
	instruction_container.size = instructions_panel.size - Vector2(20, 20)
	instructions_panel.add_child(instruction_container)
	
	# Title
	var title = Label.new()
	title.text = "How to Play Word Sort"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8, 1.0))
	instruction_container.add_child(title)
	
	# Instructions
	var instructions = """1. Click 'Start Game' to begin
2. Look at the word categories
3. Drag words to the correct category
4. Words will snap into place if correct
5. Complete all words to finish the level!

Tips:
• Click words to hear them pronounced
• Take your time to think about categories
• If unsure, try different categories
• Green means correct placement!"""
	
	var instruction_label = Label.new()
	instruction_label.text = instructions
	instruction_label.add_theme_font_size_override("font_size", 10)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_container.add_child(instruction_label)

func create_start_button():
	print("=== CREATING START GAME BUTTON ===")
	var button_container = get_node_or_null("Panel/VBoxContainer3/VBoxContainer")
	if not button_container:
		print("Cannot create start button: container not found")
		return
	
	print("Button container found, creating Start Game button...")
	var start_button = Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(190, 45)
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.add_theme_color_override("font_color", Color.BLACK)
	
	# Style button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.8, 0.3, 1.0)
	button_style.corner_radius_top_left = 13
	button_style.corner_radius_top_right = 13
	button_style.corner_radius_bottom_left = 13
	button_style.corner_radius_bottom_right = 13
	button_style.border_width_left = 5
	button_style.border_width_right = 5
	button_style.border_width_top = 5
	button_style.border_width_bottom = 5
	button_style.border_color = Color(0.167376, 0.41409, 0, 1)
	start_button.add_theme_stylebox_override("normal", button_style)
	
	print("Connecting start_game function to button...")
	start_button.pressed.connect(start_game)
	button_container.add_child(start_button)
	button_container.move_child(start_button, 0)
	print("Start Game button created and added to scene")
	print("Button text: ", start_button.text)
	print("Button is in tree: ", start_button.is_inside_tree())

func connect_navigation_buttons():
	# Connect existing navigation buttons with error checking
	print("=== CONNECTING NAVIGATION BUTTONS ===")
	
	if main_menu_btn:
		if main_menu_btn.pressed.is_connected(_on_main_menu_pressed):
			print("Main Menu button already connected")
		else:
			main_menu_btn.pressed.connect(_on_main_menu_pressed)
			print("Connected Main Menu button")
		print("Main Menu button disabled: ", main_menu_btn.disabled)
		print("Main Menu button visible: ", main_menu_btn.visible)
	else:
		print("Main Menu button not found")
		
	if game_selection_btn:
		if game_selection_btn.pressed.is_connected(_on_game_selection_pressed):
			print("Game Selection button already connected")
		else:
			game_selection_btn.pressed.connect(_on_game_selection_pressed)
			print("Connected Game Selection button")
		print("Game Selection button disabled: ", game_selection_btn.disabled)
		print("Game Selection button visible: ", game_selection_btn.visible)
	else:
		print("Game Selection button not found")
		
	if settings_btn:
		if settings_btn.pressed.is_connected(_on_settings_pressed):
			print("Settings button already connected")
		else:
			settings_btn.pressed.connect(_on_settings_pressed)
			print("Connected Settings button")
		print("Settings button disabled: ", settings_btn.disabled)
		print("Settings button visible: ", settings_btn.visible)
	else:
		print("Settings button not found")
	
	print("=======================================")




func start_game():
	if game_active:
		return
	
	if not word_sort_panel:
		print("Cannot start game: word sort panel not found")
		return
	
	game_active = true
	score = 0
	sorted_words.clear()
	
	# Get current level data
	var level_data = word_categories["level_" + str(current_level)]
	
	# Create the sorting interface
	create_sorting_interface(level_data)
	
	# Update start button
	var start_button = get_node_or_null("Panel/VBoxContainer3/VBoxContainer/StartGameButton")
	if start_button:
		start_button.text = "Playing..."
		start_button.disabled = true

func create_sorting_interface(level_data):
	if not word_sort_panel:
		return
		
	clear_word_sort_panel()
	
	# Create main horizontal container to split left/right
	var main_horizontal = HBoxContainer.new()
	main_horizontal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_horizontal.add_theme_constant_override("separation", 10)
	main_horizontal.position = Vector2(5, 5)
	main_horizontal.size = word_sort_panel.size - Vector2(10, 10)
	word_sort_panel.add_child(main_horizontal)
	
	# Left side - Categories
	var left_container = VBoxContainer.new()
	#left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_container.size_flags_stretch_ratio = 1.5  # Takes up more space
	left_container.add_theme_constant_override("separation", 10)
	main_horizontal.add_child(left_container)
	
	# Level title
	var level_title = Label.new()
	level_title.text = "Level " + str(current_level) + ": " + level_data["title"]
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title.add_theme_font_size_override("font_size", 18)
	level_title.add_theme_color_override("font_color", Color.WHITE)
	left_container.add_child(level_title)
	
	# Categories container
	var categories_container = HBoxContainer.new()
	categories_container.add_theme_constant_override("separation", 10)
	#categories_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_container.add_child(categories_container)
	
	drop_zones.clear()
	current_words.clear()
	
	# Create category drop zones
	for category_name in level_data["categories"]:
		var category_words = level_data["categories"][category_name]
		current_words += category_words
		
		var category_panel = create_category_panel(category_name)
		categories_container.add_child(category_panel)
		drop_zones.append(category_panel)
	
	# Right side - Words to sort
	var right_container = VBoxContainer.new()
	right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_container.size_flags_stretch_ratio = 1.0
	right_container.add_theme_constant_override("separation", 10)
	main_horizontal.add_child(right_container)
	
	var words_title = Label.new()
	words_title.text = "Drag these words to the correct category:"
	words_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words_title.add_theme_font_size_override("font_size", 14)
	words_title.add_theme_color_override("font_color", Color.WHITE)
	right_container.add_child(words_title)
	
	# Scrollable container for words
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_container.add_child(scroll_container)
	
	var words_grid = GridContainer.new()
	words_grid.columns = 4  # Two columns for better fit
	words_grid.add_theme_constant_override("h_separation", 8)
	words_grid.add_theme_constant_override("v_separation", 8)
	scroll_container.add_child(words_grid)
	
	# Shuffle words and create draggable buttons
	current_words.shuffle()
	for word in current_words:
		var word_button = create_word_button(word)
		words_grid.add_child(word_button)

func create_category_panel(category_name: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 350)  # Reduced height to fit better
	#panel.size_flags_horizontal = Control.SIZE_EXPAND
	panel.set_meta("category_name", category_name)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Category title
	var title_label = Label.new()
	title_label.text = category_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.position = Vector2(5, 5)
	title_label.size = Vector2(panel.custom_minimum_size.x - 10, 35)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title_label)
	
	# Scrollable container for dropped words
	var scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(5, 45)
	scroll_container.size = Vector2(panel.custom_minimum_size.x - 10, panel.custom_minimum_size.y - 50)
	panel.add_child(scroll_container)
	
	# Container for dropped words
	var words_container = VBoxContainer.new()
	words_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words_container.add_theme_constant_override("separation", 3)
	scroll_container.add_child(words_container)
	
	return panel

func create_word_button(word: String) -> Button:
	var button = Button.new()
	button.text = word
	button.custom_minimum_size = Vector2(80, 35)  # Made slightly bigger for better visibility
	button.add_theme_font_size_override("font_size", 13)
	button.set_meta("word", word)
	button.set_meta("original_parent", null)
	
	# Style the word button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color.WHITE
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color.GRAY
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_color_override("font_color", Color.BLACK)
	
	# Connect signals - only need gui_input for both clicking and dragging
	button.gui_input.connect(_on_word_input.bind(button))
	
	return button

func _on_word_clicked(word: String):
	# Play word audio for accessibility
	play_word_audio(word)

func play_word_audio(word: String):
	# Debug: Print what word we're trying to play
	print("=== AUDIO DEBUG ===")
	print("Trying to play audio for word: '", word, "'")
	
	# Try to load and play audio file for the word
	# Your audio files are in uppercase .wav format
	var word_upper = word.to_upper()
	print("Uppercase version: '", word_upper, "'")
	
	var audio_paths = [
		# Sight Words folders (most relevant for your game)
		"res://Assets/Audio Lines/Sight Words/Kinder Words/" + word_upper + ".wav",
		"res://Assets/Audio Lines/Sight Words/Grade 1 Words/" + word_upper + ".wav",
		"res://Assets/Audio Lines/Sight Words/Grade 2 Words/" + word_upper + ".wav",
		"res://Assets/Audio Lines/Sight Words/Grade 3 Words/" + word_upper + ".wav",
		"res://Assets/Audio Lines/Sight Words/Pre K Words/" + word_upper + ".wav",
		# First Grade Words folder
		"res://Assets/Audio Lines/First Grade Words/" + word_upper + ".wav",
		# Numbers folder (for level 3)
		"res://Assets/Audio Lines/Sight Words/Numbers/" + word_upper + ".wav",
		# Colors folder (for level 3)  
		"res://Assets/Audio Lines/Sight Words/Colors/" + word_upper + ".wav",
	]
	
	print("Checking these paths:")
	for i in range(audio_paths.size()):
		print(str(i + 1), ". ", audio_paths[i])
	
	var audio_played = false
	for i in range(audio_paths.size()):
		var path = audio_paths[i]
		print("Checking path ", i + 1, ": ", path)
		
		if ResourceLoader.exists(path):
			print("✓ File found at: ", path)
			var audio_stream = load(path)
			
			if audio_stream:
				print("✓ Audio stream loaded successfully")
				if word_audio:
					print("✓ AudioStreamPlayer exists")
					word_audio.stream = audio_stream
					word_audio.play()
					print("✓ Audio should be playing now")
					audio_played = true
					break
				else:
					print("✗ AudioStreamPlayer is null!")
			else:
				print("✗ Failed to load audio stream from: ", path)
		else:
			print("✗ File not found at: ", path)
	
	if not audio_played:
		print("=== AUDIO FAILED ===")
		print("No audio file found for word: '", word, "'")
		print("AudioStreamPlayer exists: ", word_audio != null)
		if word_audio:
			print("AudioStreamPlayer name: ", word_audio.name)
	else:
		print("=== AUDIO SUCCESS ===")
	
	print("===================")

func _on_word_input(event: InputEvent, button: Button):
	if not game_active:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(button, event.global_position)
			else:
				stop_drag()

func _input(event):
	if event is InputEventMouseMotion and dragging_item:
		dragging_item.global_position = event.global_position + drag_offset

func start_drag(button: Button, mouse_pos: Vector2):
	dragging_item = button
	drag_offset = button.global_position - mouse_pos
	
	# Store original position
	button.set_meta("original_parent", button.get_parent())
	button.set_meta("original_position", button.position)
	
	# Visual feedback - Changed transparency from 0.8 to 0.9 for better visibility
	button.z_index = 100
	button.modulate = Color(1.0, 1.0, 1.0, 0.9)

func stop_drag():
	if not dragging_item:
		return
	
	var mouse_pos = get_global_mouse_position()
	var dropped_in_category = false
	
	# Check if dropped in any category
	for drop_zone in drop_zones:
		if drop_zone and is_instance_valid(drop_zone):
			var zone_rect = Rect2(drop_zone.global_position, drop_zone.size)
			if zone_rect.has_point(mouse_pos):
				handle_word_drop(drop_zone)
				dropped_in_category = true
				break
	
	if not dropped_in_category:
		return_to_original_position()
	
	# Reset dragging state
	if dragging_item:
		dragging_item.z_index = 0
		dragging_item.modulate = Color.WHITE
	dragging_item = null

func handle_word_drop(drop_zone: Panel):
	var word = dragging_item.get_meta("word")
	var category = drop_zone.get_meta("category_name")
	
	# Check if word belongs in this category
	var level_data = word_categories["level_" + str(current_level)]
	var correct_words = level_data["categories"][category]
	
	if word in correct_words:
		# Correct placement
		place_word_in_category(drop_zone, word)
		score += 10
		check_level_completion()
	else:
		# Incorrect placement
		show_incorrect_feedback()
		return_to_original_position()

func place_word_in_category(drop_zone: Panel, word: String):
	# TEST AUDIO - Play the word when it's correctly placed
	print("=== TESTING AUDIO ON CORRECT PLACEMENT ===")
	play_word_audio(word)
	
	# Find the words container in the drop zone (it's inside a ScrollContainer now)
	var words_container = null
	for child in drop_zone.get_children():
		if child is ScrollContainer:
			for grandchild in child.get_children():
				if grandchild is VBoxContainer:
					words_container = grandchild
					break
			break
	
	if words_container:
		# Remove from original parent
		var original_parent = dragging_item.get_parent()
		if original_parent:
			original_parent.remove_child(dragging_item)
		
		# Create a new label for the sorted word
		var word_label = Label.new()
		word_label.text = word
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.add_theme_font_size_override("font_size", 11)
		word_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Add to category
		words_container.add_child(word_label)
		
		# Track sorted word
		sorted_words[word] = true
		
		print("Correctly placed: ", word)

func show_incorrect_feedback():
	# Visual feedback for wrong placement
	if dragging_item:
		var tween = create_tween()
		tween.tween_property(dragging_item, "modulate", Color.RED, 0.2)
		tween.tween_callback(func(): dragging_item.modulate = Color.WHITE)

func return_to_original_position():
	if not dragging_item:
		return
	
	var original_parent = dragging_item.get_meta("original_parent")
	var original_pos = dragging_item.get_meta("original_position")
	var original_global_pos = dragging_item.get_meta("original_global_position")
	
	if original_parent and is_instance_valid(original_parent):
		# Remove from current parent (likely the scene root)
		if dragging_item.get_parent():
			dragging_item.get_parent().remove_child(dragging_item)
		
		# Add back to original parent
		original_parent.add_child(dragging_item)
		
		# Restore position
		if original_pos:
			dragging_item.position = original_pos
		elif original_global_pos:
			dragging_item.global_position = original_global_pos

func check_level_completion():
	if sorted_words.size() >= current_words.size():
		level_complete()

func level_complete():
	game_active = false
	print("Level ", current_level, " complete! Score: ", score)
	
	# Celebration effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0), 0.4)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	
	# Update for next level
	current_level += 1
	var start_button = get_node_or_null("Panel/VBoxContainer3/VBoxContainer/StartGameButton")
	
	if start_button:
		if current_level <= 3:
			start_button.text = "Next Level"
		else:
			start_button.text = "Play Again"
			current_level = 1
		
		start_button.disabled = false
	else:
		print("Start button not found for level completion")

func clear_word_sort_panel():
	if word_sort_panel:
		for child in word_sort_panel.get_children():
			child.queue_free()

# Navigation handlers
func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_selection_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

func _on_settings_pressed():
	print("Settings pressed")

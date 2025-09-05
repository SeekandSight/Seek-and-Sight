extends Control

# Word Search Game for Children with Learning Disabilities
# Uses Kindergarten sight words for appropriate difficulty

# Game state variables
var game_active = false
var current_words = []
var found_words = []
var total_words = 5
var current_level = 1

# Grid variables
var grid_size = 8
var letter_grid = []
var word_positions = {}
var grid_buttons = []

# Selection variables
var is_selecting = false
var selection_start = Vector2(-1, -1)
var selection_end = Vector2(-1, -1)
var selected_cells = []

# Audio player
var word_audio: AudioStreamPlayer

# UI References - matching minigame_2.tscn structure
@onready var word_search_panel = $Panel/VBoxContainer/Panel
@onready var words_panel = $Panel/VBoxContainer2/Panel
@onready var instructions_panel = $Panel/VBoxContainer3/Panel

# Navigation buttons
@onready var main_menu_btn = $Panel/VBoxContainer3/VBoxContainer/StartButton
@onready var game_selection_btn = $Panel/VBoxContainer3/VBoxContainer/InstructionButton
@onready var settings_btn = $Panel/VBoxContainer3/VBoxContainer/SettingButton

# Kindergarten sight words organized by difficulty
var kindergarten_words = {
	"easy": ["I", "a", "go", "to", "the", "and", "you", "it", "in", "said", "for", "up", "look", "is", "her", "as", "out", "my", "have", "him"],
	"medium": ["like", "see", "play", "this", "his", "two", "love", "but", "all", "saw", "new", "day", "get", "away", "came", "then", "jump", "your", "from", "green"],
	"hard": ["because", "black", "brown", "purple", "yellow", "white", "could", "where", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
}

# Audio file paths (you'll need to add these)
var word_audio_paths = {}

func _ready():
	setup_audio_player()
	setup_word_audio_paths()
	setup_instructions()
	connect_navigation_buttons()
	create_start_button()

func setup_audio_player():
	word_audio = AudioStreamPlayer.new()
	add_child(word_audio)

func setup_word_audio_paths():
	# Map words to their audio files
	# You'll need to add audio files for each word
	var all_words = kindergarten_words["easy"] + kindergarten_words["medium"] + kindergarten_words["hard"]
	for word in all_words:
		word_audio_paths[word] = "res://Assets/Audio Lines/Sight Words/Animals/" + word.to_upper() + ".wav"

func setup_instructions():
	# Clear existing content
	for child in instructions_panel.get_children():
		if child.name == "VBoxContainer":
			continue
		child.queue_free()
	
	# Create instruction container
	var instruction_container = VBoxContainer.new()
	instruction_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_container.add_theme_constant_override("separation", 8)
	instructions_panel.add_child(instruction_container)
	instructions_panel.move_child(instruction_container, 0)
	
	# Title
	var title = Label.new()
	title.text = "How to Play Word Search"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8, 1.0))
	instruction_container.add_child(title)
	
	# Instructions
	var instructions = """1. Click 'Start Game' to begin
2. Find the words from the list
3. Click and drag to select words
4. Words can be horizontal, vertical, or diagonal
5. Found words will be highlighted
6. Find all words to complete the level!

Tips:
• Take your time to look carefully
• Words might be backwards
• Click found words to hear them"""
	
	var instruction_label = Label.new()
	instruction_label.text = instructions
	instruction_label.add_theme_font_size_override("font_size", 12)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_container.add_child(instruction_label)

func create_start_button():
	var button_container = $Panel/VBoxContainer3/VBoxContainer
	
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
	
	start_button.pressed.connect(start_game)
	button_container.add_child(start_button)
	button_container.move_child(start_button, 0)

func connect_navigation_buttons():
	# Connect existing navigation buttons - check if they exist first
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
		print("Connected Main Menu button")
	else:
		print("Main Menu button not found")
		
	if game_selection_btn:
		game_selection_btn.pressed.connect(_on_game_selection_pressed)
		print("Connected Game Selection button")
	else:
		print("Game Selection button not found")
		
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
		print("Connected Settings button")
	else:
		print("Settings button not found")

func start_game():
	if game_active:
		return
	
	game_active = true
	found_words.clear()
	
	# Select words based on current level
	select_words_for_level()
	
	# Create the game grid and word list
	create_word_search_grid()
	create_word_list()
	
	# Update start button
	var start_button = $Panel/VBoxContainer3/VBoxContainer/StartGameButton
	start_button.text = "Playing..."
	start_button.disabled = true

func select_words_for_level():
	current_words.clear()
	
	match current_level:
		1:
			# Level 1: Easy 2-3 letter words
			var easy_words = kindergarten_words["easy"]
			easy_words.shuffle()
			for i in range(min(5, easy_words.size())):
				if easy_words[i].length() <= 3:
					current_words.append(easy_words[i])
		2:
			# Level 2: Medium words
			var medium_words = kindergarten_words["medium"]
			medium_words.shuffle()
			for i in range(min(5, medium_words.size())):
				current_words.append(medium_words[i])
		_:
			# Level 3+: Hard words
			var hard_words = kindergarten_words["hard"]
			hard_words.shuffle()
			for i in range(min(4, hard_words.size())):
				current_words.append(hard_words[i])
	
	total_words = current_words.size()
	print("Level ", current_level, " words: ", current_words)

func create_word_search_grid():
	# Clear existing grid
	clear_word_search_panel()
	
	# Initialize letter grid
	letter_grid = []
	word_positions = {}
	
	for i in range(grid_size):
		letter_grid.append([])
		for j in range(grid_size):
			letter_grid[i].append("")
	
	# Place words in grid
	place_words_in_grid()
	
	# Fill empty spaces with random letters
	fill_random_letters()
	
	# Create visual grid
	create_visual_grid()

func place_words_in_grid():
	for word in current_words:
		var placed = false
		var attempts = 0
		
		while not placed and attempts < 50:
			var direction = randi() % 8  # 8 directions
			var start_row = randi() % grid_size
			var start_col = randi() % grid_size
			
			if can_place_word(word, start_row, start_col, direction):
				place_word(word, start_row, start_col, direction)
				placed = true
			
			attempts += 1
		
		if not placed:
			print("Could not place word: ", word)

func can_place_word(word: String, start_row: int, start_col: int, direction: int) -> bool:
	var directions = [
		Vector2(0, 1),   # Right
		Vector2(1, 0),   # Down
		Vector2(1, 1),   # Diagonal down-right
		Vector2(1, -1),  # Diagonal down-left
		Vector2(0, -1),  # Left
		Vector2(-1, 0),  # Up
		Vector2(-1, -1), # Diagonal up-left
		Vector2(-1, 1)   # Diagonal up-right
	]
	
	var dir = directions[direction]
	var word_upper = word.to_upper()
	
	for i in range(word_upper.length()):
		var row = start_row + dir.x * i
		var col = start_col + dir.y * i
		
		if row < 0 or row >= grid_size or col < 0 or col >= grid_size:
			return false
		
		if letter_grid[row][col] != "" and letter_grid[row][col] != word_upper[i]:
			return false
	
	return true

func place_word(word: String, start_row: int, start_col: int, direction: int):
	var directions = [
		Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(1, -1),
		Vector2(0, -1), Vector2(-1, 0), Vector2(-1, -1), Vector2(-1, 1)
	]
	
	var dir = directions[direction]
	var word_upper = word.to_upper()
	var positions = []
	
	for i in range(word_upper.length()):
		var row = start_row + dir.x * i
		var col = start_col + dir.y * i
		letter_grid[row][col] = word_upper[i]
		positions.append(Vector2(row, col))
	
	word_positions[word.to_upper()] = positions

func fill_random_letters():
	var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	
	for i in range(grid_size):
		for j in range(grid_size):
			if letter_grid[i][j] == "":
				letter_grid[i][j] = letters[randi() % letters.length()]

func create_visual_grid():
	var grid_container = GridContainer.new()
	grid_container.columns = grid_size
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	
	# Calculate button size based on panel size
	var panel_size = word_search_panel.size
	var available_size = min(panel_size.x - 20, panel_size.y - 20)
	var button_size = int(available_size / grid_size) - 4
	
	grid_container.position = Vector2(10, 10)
	word_search_panel.add_child(grid_container)
	
	grid_buttons.clear()
	
	for i in range(grid_size):
		grid_buttons.append([])
		for j in range(grid_size):
			var button = Button.new()
			button.text = letter_grid[i][j]
			button.custom_minimum_size = Vector2(button_size, button_size)
			button.add_theme_font_size_override("font_size", 16)
			
			# Style the grid button
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color.WHITE
			button_style.corner_radius_top_left = 4
			button_style.corner_radius_top_right = 4
			button_style.corner_radius_bottom_left = 4
			button_style.corner_radius_bottom_right = 4
			button_style.border_width_left = 1
			button_style.border_width_right = 1
			button_style.border_width_top = 1
			button_style.border_width_bottom = 1
			button_style.border_color = Color.GRAY
			
			button.add_theme_stylebox_override("normal", button_style)
			button.add_theme_color_override("font_color", Color.BLACK)
			
			# Connect button signals for selection
			button.gui_input.connect(_on_grid_button_input.bind(Vector2(i, j)))
			
			grid_container.add_child(button)
			grid_buttons[i].append(button)

func create_word_list():
	# Clear existing word list
	for child in words_panel.get_children():
		child.queue_free()
	
	# Create word list container
	var words_container = VBoxContainer.new()
	#words_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words_container.add_theme_constant_override("separation", 8)
	words_container.position = Vector2(10, 10)
	words_panel.add_child(words_container)
	
	# Add title
	var title = Label.new()
	title.text = "Find These Words:"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE_SMOKE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words_container.add_child(title)
	
	# Add word buttons
	for word in current_words:
		var word_button = Button.new()
		word_button.text = word.to_upper()
		word_button.custom_minimum_size = Vector2(150, 30)
		word_button.add_theme_font_size_override("font_size", 16)
		
		# Style word button
		var word_style = StyleBoxFlat.new()
		word_style.bg_color = Color(0.7, 0.7, 0.7, 1.0)
		word_style.corner_radius_top_left = 8
		word_style.corner_radius_top_right = 8
		word_style.corner_radius_bottom_left = 8
		word_style.corner_radius_bottom_right = 8
		word_button.add_theme_stylebox_override("normal", word_style)
		word_button.add_theme_color_override("font_color", Color.BLACK)
		
		# Connect to play word audio
		word_button.pressed.connect(_on_word_button_clicked.bind(word))
		
		words_container.add_child(word_button)

func _on_grid_button_input(event: InputEvent, pos: Vector2):
	if not game_active:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_selection(pos)
			else:
				end_selection(pos)

func start_selection(pos: Vector2):
	is_selecting = true
	selection_start = pos
	selection_end = pos
	update_selection_visual()

func end_selection(pos: Vector2):
	if not is_selecting:
		return
	
	selection_end = pos
	check_word_selection()
	clear_selection_visual()
	is_selecting = false

func _input(event):
	if event is InputEventMouseMotion and is_selecting:
		# Find which grid cell the mouse is over
		var mouse_pos = get_global_mouse_position()
		var grid_pos = find_grid_position_at_mouse(mouse_pos)
		if grid_pos != Vector2(-1, -1):
			selection_end = grid_pos
			update_selection_visual()

func find_grid_position_at_mouse(mouse_pos: Vector2) -> Vector2:
	for i in range(grid_size):
		for j in range(grid_size):
			if grid_buttons[i][j]:
				var button_rect = Rect2(grid_buttons[i][j].global_position, grid_buttons[i][j].size)
				if button_rect.has_point(mouse_pos):
					return Vector2(i, j)
	return Vector2(-1, -1)

func update_selection_visual():
	# Clear previous selection
	clear_selection_visual()
	
	# Highlight current selection
	selected_cells = get_cells_between(selection_start, selection_end)
	
	for cell in selected_cells:
		if cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size:
			var button = grid_buttons[int(cell.x)][int(cell.y)]
			button.modulate = Color.YELLOW

func clear_selection_visual():
	for cell in selected_cells:
		if cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size:
			var button = grid_buttons[int(cell.x)][int(cell.y)]
			if button.get_meta("found", false):
				button.modulate = Color.GREEN
			else:
				button.modulate = Color.WHITE
	selected_cells.clear()

func get_cells_between(start: Vector2, end: Vector2) -> Array:
	var cells = []
	
	var dx = end.x - start.x
	var dy = end.y - start.y
	var steps = int(max(abs(dx), abs(dy)))
	
	if steps == 0:
		cells.append(start)
		return cells
	
	var x_step = dx / steps
	var y_step = dy / steps
	
	for i in range(steps + 1):
		var x = int(start.x + x_step * i)
		var y = int(start.y + y_step * i)
		cells.append(Vector2(x, y))
	
	return cells

func check_word_selection():
	var selected_letters = ""
	
	for cell in selected_cells:
		if cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size:
			selected_letters += letter_grid[int(cell.x)][int(cell.y)]
	
	# Check forward and backward
	var forward_word = selected_letters
	var backward_word = ""
	for i in range(selected_letters.length() - 1, -1, -1):
		backward_word += selected_letters[i]
	
	var found_word = ""
	
	# Check if selection matches any target word
	for word in current_words:
		var word_upper = word.to_upper()
		if forward_word == word_upper or backward_word == word_upper:
			found_word = word
			break
	
	if found_word != "" and found_word not in found_words:
		word_found(found_word)

func word_found(word: String):
	found_words.append(word)
	print("Found word: ", word)
	
	# Highlight the word in the grid
	for cell in selected_cells:
		if cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size:
			var button = grid_buttons[int(cell.x)][int(cell.y)]
			button.modulate = Color.GREEN
			button.set_meta("found", true)
	
	# Update word list to show found word
	update_word_list_display()
	
	# Play word audio
	play_word_audio(word)
	
	# Check if all words found
	if found_words.size() >= total_words:
		level_complete()

func update_word_list_display():
	var words_container = words_panel.get_child(0)
	if not words_container:
		return
	
	for i in range(1, words_container.get_child_count()):  # Skip title
		var word_button = words_container.get_child(i)
		var word = word_button.text.to_lower()
		
		if word in found_words:
			var found_style = StyleBoxFlat.new()
			found_style.bg_color = Color.GREEN
			found_style.corner_radius_top_left = 8
			found_style.corner_radius_top_right = 8
			found_style.corner_radius_bottom_left = 8
			found_style.corner_radius_bottom_right = 8
			word_button.add_theme_stylebox_override("normal", found_style)
			word_button.add_theme_color_override("font_color", Color.WHITE)

func level_complete():
	game_active = false
	print("Level ", current_level, " complete!")
	
	# Celebration effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0), 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Update start button for next level
	current_level += 1
	var start_button = $Panel/VBoxContainer3/VBoxContainer/StartGameButton
	start_button.text = "Next Level"
	start_button.disabled = false

func play_word_audio(word: String):
	if word in word_audio_paths:
		var audio_path = word_audio_paths[word]
		if ResourceLoader.exists(audio_path):
			var audio_stream = load(audio_path)
			if audio_stream:
				word_audio.stream = audio_stream
				word_audio.play()

func _on_word_button_clicked(word: String):
	play_word_audio(word)

func clear_word_search_panel():
	for child in word_search_panel.get_children():
		child.queue_free()

# Navigation handlers
func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_selection_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

func _on_settings_pressed():
	print("Settings pressed")

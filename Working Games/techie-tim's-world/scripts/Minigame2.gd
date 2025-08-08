extends Control

# Node references - Using correct paths from your scene structure
@onready var maze_container = $MainContainer/GameContent/LeftPanel/MazeContainer
@onready var moves_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/MovesLabel
@onready var timer_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/TimerLabel
@onready var status_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/StatusLabel
@onready var current_level_label = $MainContainer/Header/LevelContainer/CurrentLevelLabel

# Command builder UI (NEW)
@onready var command_queue_container = $MainContainer/GameContent/RightPanel/CommandBuilderPanel/CommandBuilderContainer/CommandQueue
@onready var run_program_button = $MainContainer/GameContent/RightPanel/CommandBuilderPanel/CommandBuilderContainer/CommandButtons/RunProgramButton
@onready var clear_code_button = $MainContainer/GameContent/RightPanel/CommandBuilderPanel/CommandBuilderContainer/CommandButtons/ClearCodeButton

# Direction buttons (now build commands instead of immediate movement)
@onready var up_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/DirectionButtons/UpButton
@onready var down_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/DirectionButtons/DownButton
@onready var left_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/DirectionButtons/MiddleRow/LeftButton
@onready var right_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/DirectionButtons/MiddleRow/RightButton

# Level buttons
@onready var level1_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer/Level1Button
@onready var level2_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer/Level2Button
@onready var level3_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer/Level3Button
@onready var level4_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer/Level4Button
@onready var level5_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer/Level5Button

# Game buttons
@onready var reset_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/GameButtons/ResetButton
@onready var main_menu_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/GameButtons/MainMenuButton
@onready var game_select_button = $MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/GameButtons/GameSelectButton

# Programming concepts (NEW)
var command_queue = []  # Array of commands to execute
var max_commands = 8   # Limit commands for difficulty progression
var is_executing = false
var execution_speed = 0.5  # Seconds between command execution
var command_labels = []    # Visual representation of commands

# Game variables
var current_level = 1
var max_level = 5
var grid_size = Vector2(8, 8)
var cell_size = 48
var tim_position = Vector2(0, 0)
var end_position = Vector2(7, 7)
var maze_grid = []
var tim_sprite: Sprite2D
var maze_cells = []
var moves_count = 0
var game_won = false
var start_time = 0.0
var game_timer = 0.0
var timer_running = false
var level_buttons = []

# Responsive design variables
var screen_size: Vector2
var is_mobile: bool = false
var scale_factor: float = 1.0

# Audio system (DISABLED - add audio files later)
var audio_player: AudioStreamPlayer
var audio_enabled = false  # Set to true when you add audio files
var sound_effects = {}

# Command types enum for clarity
enum Commands {
	MOVE_UP,
	MOVE_DOWN, 
	MOVE_LEFT,
	MOVE_RIGHT
}

# Multiple maze layouts for different levels
var maze_layouts = {
	1: [  # Level 1 - Easy (clear corridor path)
		[1, 1, 1, 1, 1, 0, 0, 0],
		[0, 0, 0, 0, 1, 0, 1, 1],
		[0, 1, 1, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0, 0, 0, 1]
	],
	2: [  # Level 2 - Easy-Medium (simple L-path)
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 1]
	],
	3: [  # Level 3 - Medium (zigzag path)
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 0, 1, 1, 1, 0],
		[0, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 1, 1, 0, 1, 0],
		[1, 0, 0, 0, 0, 0, 1, 0],
		[1, 1, 1, 1, 1, 1, 1, 1]
	],
	4: [  # Level 4 - Hard (spiral path)
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 1, 1, 0],
		[0, 1, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1]
	],
	5: [  # Level 5 - Expert (complex but clear path)
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 0, 1, 1, 1, 0],
		[0, 0, 1, 0, 1, 0, 1, 0],
		[1, 1, 1, 0, 1, 0, 1, 0],
		[1, 0, 0, 0, 1, 0, 1, 0],
		[1, 1, 1, 1, 1, 0, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 1, 1, 1]
	]
}

# Enhanced color scheme with tech aesthetic
var colors = {
	"path": Color(0.1, 0.8, 0.4, 1),        # Bright green circuit paths
	"wall": Color(0.8, 0.1, 0.2, 1),        # Red blocked circuits
	"start": Color(0.2, 1, 0.2, 1),         # Bright green start terminal
	"goal": Color(0.0, 0.6, 1, 1),          # Blue goal terminal
	"trail": Color(1, 0.8, 0.2, 1),         # Yellow execution trail
	"current": Color(0.8, 0.2, 1, 1),       # Purple - Tim's current position
	"command_bg": Color(0.1, 0.1, 0.3, 0.9), # Dark blue command blocks
	"command_text": Color(0.9, 0.9, 1, 1)   # Light text for commands
}

func _ready():
	# Setup audio player (disabled until audio files are added)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_enabled = false  # Enable when you add audio files
	
	# Detect screen size and adjust for responsive design
	detect_screen_size()
	setup_responsive_ui()
	setup_level_buttons()
	load_level(current_level)
	connect_signals()
	start_game()
	
	# Connect to screen resize events
	get_viewport().size_changed.connect(_on_screen_resized)

func detect_screen_size():
	"""Detect screen size and set responsive parameters"""
	screen_size = get_viewport().get_visible_rect().size
	print("Screen size detected: ", screen_size)
	
	# Determine if mobile/small screen
	is_mobile = screen_size.x < 800 or screen_size.y < 600
	
	# Calculate scale factor based on screen size
	var base_width = 1200.0  # Reference desktop width
	scale_factor = screen_size.x / base_width
	scale_factor = clamp(scale_factor, 0.5, 2.0)  # Limit scaling range
	
	print("Mobile device: ", is_mobile)
	print("Scale factor: ", scale_factor)

func setup_responsive_ui():
	"""Adjust UI elements for different screen sizes"""
	if is_mobile:
		setup_mobile_layout()
	else:
		setup_desktop_layout()

func setup_mobile_layout():
	"""Optimize layout for mobile devices"""
	print("Setting up mobile layout")
	
	# Adjust font sizes for mobile
	var title_size = int(48 * scale_factor)
	var header_size = int(20 * scale_factor)
	var button_size = int(16 * scale_factor)
	
	# Apply responsive font sizes
	if current_level_label:
		current_level_label.add_theme_font_size_override("font_size", header_size)
	if moves_label:
		moves_label.add_theme_font_size_override("font_size", header_size)
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", header_size)
	if status_label:
		status_label.add_theme_font_size_override("font_size", int(14 * scale_factor))
	
	# Adjust button sizes for mobile
	var button_height = int(45 * scale_factor)
	var button_width = int(80 * scale_factor)
	
	adjust_button_sizes(button_width, button_height)

func setup_desktop_layout():
	"""Optimize layout for desktop"""
	print("Setting up desktop layout")
	
	# Desktop uses original sizes but scaled
	var title_size = int(72 * scale_factor)
	var header_size = int(24 * scale_factor)
	var button_size = int(18 * scale_factor)
	
	# Apply scaled font sizes
	if moves_label:
		moves_label.add_theme_font_size_override("font_size", header_size)
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", header_size)
	if status_label:
		status_label.add_theme_font_size_override("font_size", int(16 * scale_factor))
	
	# Standard button sizes scaled
	var button_height = int(50 * scale_factor)
	var button_width = int(100 * scale_factor)
	
	adjust_button_sizes(button_width, button_height)

func adjust_button_sizes(width: int, height: int):
	"""Adjust all button sizes for responsiveness"""
	var buttons = [up_button, down_button, left_button, right_button, reset_button, run_program_button, clear_code_button]
	
	for button in buttons:
		if button:
			button.custom_minimum_size = Vector2(width, height)
			button.add_theme_font_size_override("font_size", int(16 * scale_factor))
	
	# Level buttons (smaller)
	var level_size = int(35 * scale_factor)
	for button in level_buttons:
		if button:
			button.custom_minimum_size = Vector2(level_size, level_size)
			button.add_theme_font_size_override("font_size", int(14 * scale_factor))

func _on_screen_resized():
	"""Handle screen resize events"""
	print("Screen resized")
	detect_screen_size()
	setup_responsive_ui()
	# Recreate maze with new sizing
	if maze_grid.size() > 0:
		setup_maze()
		setup_tim()

func setup_level_buttons():
	"""Setup level selection buttons"""
	level_buttons = [level1_button, level2_button, level3_button, level4_button, level5_button]
	
	for i in range(level_buttons.size()):
		var button = level_buttons[i]
		if button == null:
			print("Level button ", i+1, " is null")
			continue
			
		var level_num = i + 1
		button.pressed.connect(_on_level_selected.bind(level_num))
		
		# Highlight current level
		if level_num == current_level:
			button.modulate = Color(1.2, 1.2, 1.2, 1)
		else:
			button.modulate = Color(0.8, 0.8, 0.8, 1)

func load_level(level_num: int):
	"""Load a specific level"""
	if level_num < 1 or level_num > max_level:
		return
	
	current_level = level_num
	current_level_label.text = str(current_level)
	
	# Adjust command limit based on level (progressive difficulty)
	match current_level:
		1, 2:
			max_commands = 6
		3, 4:
			max_commands = 8
		5:
			max_commands = 10
	
	# Load maze layout for this level
	maze_grid = maze_layouts[current_level].duplicate(true)
	
	# Update level button highlights
	for i in range(level_buttons.size()):
		if level_buttons[i]:
			if i + 1 == current_level:
				level_buttons[i].modulate = Color(1.2, 1.2, 1.2, 1)
			else:
				level_buttons[i].modulate = Color(0.8, 0.8, 0.8, 1)
	
	setup_maze()
	setup_tim()
	clear_command_queue()

func setup_maze():
	"""Initialize the visual maze grid with responsive sizing"""
	# Clear any existing maze cells
	for child in maze_container.get_children():
		child.queue_free()
	maze_cells.clear()
	
	# Calculate responsive cell size
	var container_size = maze_container.size
	if container_size == Vector2.ZERO:
		if is_mobile:
			container_size = Vector2(300, 300)
		else:
			container_size = Vector2(450, 450)
	
	var available_width = container_size.x - 20
	var available_height = container_size.y - 20
	var max_cell_size = min(available_width / grid_size.x, available_height / grid_size.y)
	cell_size = max(max_cell_size - 2, 20)
	
	print("Container size: ", container_size)
	print("Calculated cell size: ", cell_size)
	
	# Create visual maze with tech aesthetic
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(x * (cell_size + 2) + 10, y * (cell_size + 2) + 10)
			
			# Tech-themed color coding
			if x == 0 and y == 0:
				cell.color = colors.start
			elif x == end_position.x and y == end_position.y:
				cell.color = colors.goal
			elif maze_grid[y][x] == 1:
				cell.color = colors.path
			else:
				cell.color = colors.wall
			
			# Add subtle border for tech look
			var border = ColorRect.new()
			border.size = Vector2(cell_size + 2, cell_size + 2)
			border.position = Vector2(x * (cell_size + 2) + 9, y * (cell_size + 2) + 9)
			border.color = Color(0.3, 0.8, 1, 0.3)  # Subtle blue border
			border.z_index = -1
			maze_container.add_child(border)
			
			maze_container.add_child(cell)
			row.append(cell)
		maze_cells.append(row)

func setup_tim():
	"""Create and position Tim sprite with responsive scaling"""
	if tim_sprite:
		tim_sprite.queue_free()
	
	tim_sprite = Sprite2D.new()
	var tim_texture = preload("res://Assests/images/TimNeutral-removebg-preview.png")
	tim_sprite.texture = tim_texture
	
	# Responsive Tim scaling
	var tim_scale = (cell_size / 200.0) * scale_factor
	tim_scale = clamp(tim_scale, 0.08, 0.25)
	tim_sprite.scale = Vector2(tim_scale, tim_scale)
	
	print("Tim scale: ", tim_scale)
	
	update_tim_position()
	maze_container.add_child(tim_sprite)

func connect_signals():
	"""Connect all button signals - NOW FOR COMMAND BUILDING"""
	# Direction buttons now ADD commands instead of moving immediately
	up_button.pressed.connect(_on_add_command.bind(Commands.MOVE_UP))
	down_button.pressed.connect(_on_add_command.bind(Commands.MOVE_DOWN))
	left_button.pressed.connect(_on_add_command.bind(Commands.MOVE_LEFT))
	right_button.pressed.connect(_on_add_command.bind(Commands.MOVE_RIGHT))
	
	# NEW: Program execution buttons
	run_program_button.pressed.connect(_on_run_program)
	clear_code_button.pressed.connect(_on_clear_code)
	
	reset_button.pressed.connect(_on_reset_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	game_select_button.pressed.connect(_on_game_select_pressed)

func start_game():
	"""Initialize game state"""
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	is_executing = false
	start_time = Time.get_time_dict_from_system()["second"]
	timer_running = true
	clear_command_queue()
	update_ui()
	show_status("🤖 LEVEL " + str(current_level) + " LOADED! Program Tim's path to the BLUE terminal!")
	
	# Update button text to reflect programming theme
	up_button.text = "⬆ MOVE UP"
	down_button.text = "⬇ MOVE DOWN"
	left_button.text = "⬅ MOVE LEFT"
	right_button.text = "➡ MOVE RIGHT"

# NEW PROGRAMMING FUNCTIONS

func _on_add_command(command: Commands):
	"""Add a command to the programming queue"""
	if is_executing or game_won:
		return
	
	if command_queue.size() >= max_commands:
		show_status("⚠️ COMMAND LIMIT REACHED! Max " + str(max_commands) + " commands per program.")
		play_sound("error")
		return
	
	# Add command to queue
	command_queue.append(command)
	play_sound("command_added")
	
	# Update visual command queue
	update_command_queue_display()
	
	# Update status with programming language
	var command_name = get_command_name(command)
	show_status("✅ COMMAND ADDED: " + command_name + " | Commands: " + str(command_queue.size()) + "/" + str(max_commands))

func _on_run_program():
	"""Execute the programmed sequence"""
	if is_executing or game_won or command_queue.is_empty():
		return
	
	if command_queue.is_empty():
		show_status("❌ NO PROGRAM TO RUN! Add commands first.")
		play_sound("error")
		return
	
	show_status("🚀 EXECUTING PROGRAM... " + str(command_queue.size()) + " COMMANDS")
	play_sound("program_start")
	
	is_executing = true
	disable_programming_buttons()
	
	# Execute commands one by one with delay
	execute_next_command(0)

func _on_clear_code():
	"""Clear all commands from the queue"""
	if is_executing:
		return
		
	clear_command_queue()
	show_status("🗑️ PROGRAM CLEARED! Ready to code a new path for Tim.")
	play_sound("debug")

func clear_command_queue():
	"""Clear command queue and update display"""
	command_queue.clear()
	update_command_queue_display()
	enable_programming_buttons()
	is_executing = false

func execute_next_command(index: int):
	"""Execute commands sequentially with animation"""
	if index >= command_queue.size():
		# Program execution complete
		is_executing = false
		enable_programming_buttons()
		show_status("✅ PROGRAM EXECUTION COMPLETE!")
		return
	
	var command = command_queue[index]
	var direction = get_direction_from_command(command)
	var command_name = get_command_name(command)
	
	# Highlight current command being executed
	highlight_current_command(index)
	
	show_status("⚡ EXECUTING: " + command_name + " (" + str(index + 1) + "/" + str(command_queue.size()) + ")")
	play_sound("command_execute")
	
	# Check if move is valid
	var new_position = tim_position + direction
	
	# Check bounds
	if new_position.x < 0 or new_position.x >= grid_size.x or \
	   new_position.y < 0 or new_position.y >= grid_size.y:
		handle_program_error("🚫 ERROR: BOUNDARY VIOLATION! Tim tried to move outside the grid.", index)
		return
	
	# Check if target cell is walkable
	if maze_grid[new_position.y][new_position.x] == 0:
		handle_program_error("🧱 ERROR: WALL COLLISION! Tim hit a wall at command " + str(index + 1) + ".", index)
		return
	
	# Valid move - execute it
	tim_position = new_position
	moves_count += 1
	mark_path_cell(tim_position)
	animate_tim_movement()
	update_ui()
	
	# Check win condition
	if tim_position == end_position:
		win_game()
		return
	
	# Continue to next command after delay
	await get_tree().create_timer(execution_speed).timeout
	execute_next_command(index + 1)

func handle_program_error(error_message: String, failed_command_index: int):
	"""Handle execution errors with debugging info"""
	is_executing = false
	enable_programming_buttons()
	
	show_status("❌ " + error_message + " 🔧 DEBUG YOUR CODE!")
	play_sound("error")
	
	# Highlight the failed command
	highlight_failed_command(failed_command_index)
	
	# Flash Tim's position to show where the error occurred
	flash_tim_error()

func update_command_queue_display():
	"""Update the visual representation of the command queue"""
	# Clear existing command labels
	for label in command_labels:
		if label:
			label.queue_free()
	command_labels.clear()
	
	# Create new command labels
	for i in range(command_queue.size()):
		var command = command_queue[i]
		var command_name = get_command_name(command)
		
		var command_block = create_command_block(command_name, i)
		command_queue_container.add_child(command_block)
		command_labels.append(command_block)

func create_command_block(command_text: String, index: int) -> Control:
	"""Create a visual command block with tech aesthetic"""
	var block = Panel.new()
	block.custom_minimum_size = Vector2(120, 30)
	
	# Tech-styled background
	var style = StyleBoxFlat.new()
	style.bg_color = colors.command_bg
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.8, 1, 0.8)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	block.add_theme_stylebox_override("panel", style)
	
	# Command text
	var label = Label.new()
	label.text = str(index + 1) + ". " + command_text
	label.add_theme_color_override("font_color", colors.command_text)
	label.add_theme_font_size_override("font_size", int(14 * scale_factor))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	
	block.add_child(label)
	return block

func highlight_current_command(index: int):
	"""Highlight the command currently being executed"""
	if index < command_labels.size() and command_labels[index]:
		var block = command_labels[index]
		var tween = create_tween()
		tween.tween_property(block, "modulate", Color(1.5, 1.5, 1, 1), 0.2)
		tween.tween_property(block, "modulate", Color(1, 1, 1, 1), 0.2)

func highlight_failed_command(index: int):
	"""Highlight the command that caused an error"""
	if index < command_labels.size() and command_labels[index]:
		var block = command_labels[index]
		block.modulate = Color(1.5, 0.5, 0.5, 1)  # Red highlight for error

func flash_tim_error():
	"""Flash Tim's sprite to indicate error location"""
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(tim_sprite, "modulate", Color(1.5, 0.5, 0.5, 1), 0.2)
	tween.tween_property(tim_sprite, "modulate", Color(1, 1, 1, 1), 0.2)

func disable_programming_buttons():
	"""Disable programming UI during execution"""
	up_button.disabled = true
	down_button.disabled = true
	left_button.disabled = true
	right_button.disabled = true
	run_program_button.disabled = true
	clear_code_button.disabled = true

func enable_programming_buttons():
	"""Re-enable programming UI"""
	if not game_won:
		up_button.disabled = false
		down_button.disabled = false
		left_button.disabled = false
		right_button.disabled = false
		run_program_button.disabled = false
		clear_code_button.disabled = false

func get_command_name(command: Commands) -> String:
	"""Convert command enum to display string"""
	match command:
		Commands.MOVE_UP:
			return "MOVE UP"
		Commands.MOVE_DOWN:
			return "MOVE DOWN"
		Commands.MOVE_LEFT:
			return "MOVE LEFT"
		Commands.MOVE_RIGHT:
			return "MOVE RIGHT"
		_:
			return "UNKNOWN"

func get_direction_from_command(command: Commands) -> Vector2:
	"""Convert command enum to direction vector"""
	match command:
		Commands.MOVE_UP:
			return Vector2(0, -1)
		Commands.MOVE_DOWN:
			return Vector2(0, 1)
		Commands.MOVE_LEFT:
			return Vector2(-1, 0)
		Commands.MOVE_RIGHT:
			return Vector2(1, 0)
		_:
			return Vector2.ZERO

func play_sound(sound_name: String):
	"""Play sound effects - currently disabled until audio files are added"""
	if audio_enabled and sound_effects.has(sound_name) and audio_player:
		audio_player.stream = sound_effects[sound_name]
		audio_player.play()
	else:
		# For now, just print what sound would play (for debugging)
		print("🔊 SOUND: " + sound_name)

# EXISTING FUNCTIONS (Enhanced with Programming Theme)

func _on_level_selected(level_num: int):
	"""Handle level selection"""
	if level_num != current_level and not is_executing:
		load_level(level_num)
		start_game()

func animate_tim_movement():
	"""Smooth movement animation for Tim with tech effects"""
	var target_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10-15
	)
	
	var tween = create_tween()
	tween.tween_property(tim_sprite, "position", target_pos, 0.25)
	
	# Add subtle tech effect during movement
	var original_modulate = tim_sprite.modulate
	tween.parallel().tween_property(tim_sprite, "modulate", Color(0.5, 1, 1, 1), 0.125)
	tween.tween_property(tim_sprite, "modulate", original_modulate, 0.125)

func update_tim_position():
	"""Update Tim's visual position on the maze"""
	var pixel_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	tim_sprite.position = pixel_pos

func mark_path_cell(pos: Vector2):
	"""Mark cells that Tim has visited with tech trail effect"""
	if pos != Vector2(0, 0) and pos != end_position:
		maze_cells[pos.y][pos.x].color = colors.trail
		
		# Add subtle glow effect to trail
		var tween = create_tween()
		var original_color = colors.trail
		var bright_color = Color(original_color.r * 1.3, original_color.g * 1.3, original_color.b * 1.3, 1)
		tween.tween_property(maze_cells[pos.y][pos.x], "color", bright_color, 0.2)
		tween.tween_property(maze_cells[pos.y][pos.x], "color", original_color, 0.3)

func update_ui():
	"""Update all UI elements with programming terminology"""
	moves_label.text = "COMMANDS EXECUTED: " + str(moves_count)
	
	if timer_running:
		var current_time = Time.get_time_dict_from_system()["second"]
		game_timer = current_time - start_time
		var minutes = int(game_timer) / 60
		var seconds = int(game_timer) % 60
		timer_label.text = "RUNTIME: %02d:%02d" % [minutes, seconds]

func show_status(message: String):
	"""Update status display with tech formatting"""
	status_label.text = message

func win_game():
	"""Handle win condition with programming celebration"""
	game_won = true
	timer_running = false
	is_executing = false
	
	show_status("🎉 PROGRAM SUCCESSFUL! LEVEL " + str(current_level) + " COMPLETE! 🎉")
	play_sound("success")
	
	# Disable all programming UI
	disable_programming_buttons()
	
	# Tech celebration - highlight goal with circuit pattern
	maze_cells[end_position.y][end_position.x].color = Color.GOLD
	
	# Celebration animation with tech theme
	var tween = create_tween()
	tween.set_loops(3)
	var current_scale = tim_sprite.scale.x
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale * 1.3, current_scale * 1.3), 0.2)
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale, current_scale), 0.2)
	
	# Auto-advance to next level after celebration
	await get_tree().create_timer(3.0).timeout
	if current_level < max_level:
		show_status("🚀 LOADING NEXT PROGRAMMING CHALLENGE...")
		await get_tree().create_timer(1.0).timeout
		load_level(current_level + 1)
		reset_game_state()
		start_game()
	else:
		show_status("🏆 ALL SYSTEMS DEBUGGED! You're a master programmer! 🏆")

func reset_game_state():
	"""Reset game state for new level"""
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	is_executing = false
	timer_running = true
	start_time = Time.get_time_dict_from_system()["second"]
	
	clear_command_queue()
	update_tim_position()

func _on_reset_pressed():
	"""Reset the current level to initial state"""
	if is_executing:
		return  # Don't allow reset during execution
		
	reset_game_state()
	
	# Reset maze colors to original state
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			if x == 0 and y == 0:
				maze_cells[y][x].color = colors.start
			elif x == end_position.x and y == end_position.y:
				maze_cells[y][x].color = colors.goal
			elif maze_grid[y][x] == 1:
				maze_cells[y][x].color = colors.path
			else:
				maze_cells[y][x].color = colors.wall
	
	update_ui()
	show_status("🔄 SYSTEM RESET! Program Tim's path to the BLUE terminal.")
	play_sound("debug")

func _on_main_menu_pressed():
	"""Return to main menu"""
	if is_executing:
		return  # Don't allow menu change during execution
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	"""Go to game selection screen"""
	if is_executing:
		return  # Don't allow game change during execution
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Enhanced keyboard input with programming shortcuts
func _input(event):
	if game_won or is_executing:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				_on_add_command(Commands.MOVE_UP)
			KEY_DOWN, KEY_S:
				_on_add_command(Commands.MOVE_DOWN)
			KEY_LEFT, KEY_A:
				_on_add_command(Commands.MOVE_LEFT)
			KEY_RIGHT, KEY_D:
				_on_add_command(Commands.MOVE_RIGHT)
			KEY_ENTER, KEY_SPACE:  # Run program
				_on_run_program()
			KEY_BACKSPACE, KEY_DELETE:  # Clear program
				_on_clear_code()
			KEY_R:  # Reset
				_on_reset_pressed()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:  # Level selection
				var level_num = event.keycode - KEY_0
				if level_num >= 1 and level_num <= max_level:
					_on_level_selected(level_num)

# Accessibility helper functions
func get_current_status_for_screen_reader() -> String:
	"""Provide detailed status for screen readers"""
	var status = "Tim is at position " + str(tim_position) + ". "
	status += "Commands in queue: " + str(command_queue.size()) + " of " + str(max_commands) + ". "
	if is_executing:
		status += "Program is currently executing. "
	elif game_won:
		status += "Level complete! "
	else:
		status += "Ready to add commands. "
	return status

func announce_command_added(command: Commands):
	"""Announce command additions for accessibility"""
	var command_name = get_command_name(command)
	var announcement = "Added command: " + command_name + ". Total commands: " + str(command_queue.size())
	# This would integrate with screen reader APIs in a real implementation
	print("ACCESSIBILITY: " + announcement)

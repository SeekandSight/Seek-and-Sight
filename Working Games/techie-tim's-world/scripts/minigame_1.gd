extends Control

# Node references - Using correct paths from your scene structure
@onready var maze_container = $MainContainer/GameContent/LeftPanel/MazeContainer
@onready var moves_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/MovesLabel
@onready var timer_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/TimerLabel
@onready var status_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/StatusLabel
@onready var current_level_label = $MainContainer/Header/LevelContainer/CurrentLevelLabel

# Direction buttons
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

# Game variables
var current_level = 1
var max_level = 5
var grid_size = Vector2(8, 8)
var cell_size = 48  # This will be calculated dynamically
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

# Multiple maze layouts for different levels - PROPERLY DESIGNED SOLVABLE MAZES
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

# Enhanced color scheme
var colors = {
	"path": Color(0.2, 0.8, 0.4, 1),        # Green paths
	"wall": Color(0.8, 0.2, 0.3, 1),        # Red walls  
	"start": Color(0.3, 1, 0.3, 1),         # Bright green start
	"goal": Color(0.2, 0.6, 1, 1),          # Clear BLUE goal (instead of cyan)
	"trail": Color(1, 0.8, 0.2, 1)          # Yellow trail
}

func _ready():
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
		# Mobile-specific adjustments
		setup_mobile_layout()
	else:
		# Desktop layout (current design is fine)
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
	var buttons = [up_button, down_button, left_button, right_button, reset_button]
	
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
	
	# Load maze layout for this level
	maze_grid = maze_layouts[current_level].duplicate(true)
	
	# Update level button highlights
	for i in range(level_buttons.size()):
		if level_buttons[i]:  # Check if button exists
			if i + 1 == current_level:
				level_buttons[i].modulate = Color(1.2, 1.2, 1.2, 1)
			else:
				level_buttons[i].modulate = Color(0.8, 0.8, 0.8, 1)
	
	setup_maze()
	setup_tim()

func setup_maze():
	"""Initialize the visual maze grid with responsive sizing"""
	# Clear any existing maze cells
	for child in maze_container.get_children():
		child.queue_free()
	maze_cells.clear()
	
	# Calculate responsive cell size based on container and screen size
	var container_size = maze_container.size
	if container_size == Vector2.ZERO:
		# Use default size if container not ready
		if is_mobile:
			container_size = Vector2(300, 300)
		else:
			container_size = Vector2(450, 450)
	
	# Calculate optimal cell size with padding
	var available_width = container_size.x - 20  # 10px padding on each side
	var available_height = container_size.y - 20
	
	# Use the smaller dimension to ensure square cells fit
	var max_cell_size = min(available_width / grid_size.x, available_height / grid_size.y)
	cell_size = max(max_cell_size - 2, 20)  # Minimum 20px cells, -2 for spacing
	
	print("Container size: ", container_size)
	print("Calculated cell size: ", cell_size)
	
	# Create visual maze with responsive sizing
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(x * (cell_size + 2) + 10, y * (cell_size + 2) + 10)
			
			# Color coding
			if x == 0 and y == 0:
				cell.color = colors.start
			elif x == end_position.x and y == end_position.y:
				cell.color = colors.goal
			elif maze_grid[y][x] == 1:
				cell.color = colors.path
			else:
				cell.color = colors.wall
			
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
	
	# Responsive Tim scaling based on cell size
	var tim_scale = (cell_size / 200.0) * scale_factor  # Base scale relative to cell size
	tim_scale = clamp(tim_scale, 0.08, 0.25)  # Reasonable size limits
	tim_sprite.scale = Vector2(tim_scale, tim_scale)
	
	print("Tim scale: ", tim_scale)
	
	update_tim_position()
	maze_container.add_child(tim_sprite)

func connect_signals():
	"""Connect all button signals"""
	up_button.pressed.connect(_on_direction_button_pressed.bind(Vector2(0, -1)))
	down_button.pressed.connect(_on_direction_button_pressed.bind(Vector2(0, 1)))
	left_button.pressed.connect(_on_direction_button_pressed.bind(Vector2(-1, 0)))
	right_button.pressed.connect(_on_direction_button_pressed.bind(Vector2(1, 0)))
	
	reset_button.pressed.connect(_on_reset_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	game_select_button.pressed.connect(_on_game_select_pressed)

func start_game():
	"""Initialize game state"""
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	start_time = Time.get_time_dict_from_system()["second"]
	timer_running = true
	update_ui()
	show_status("Level " + str(current_level) + " loaded! Guide Tim to the BLUE goal!")

func _on_level_selected(level_num: int):
	"""Handle level selection"""
	if level_num != current_level:
		load_level(level_num)
		start_game()

func _on_direction_button_pressed(direction: Vector2):
	"""Handle directional movement"""
	if game_won:
		return
		
	var new_position = tim_position + direction
	
	# Check bounds
	if new_position.x < 0 or new_position.x >= grid_size.x or \
	   new_position.y < 0 or new_position.y >= grid_size.y:
		show_status("🚫 Out of bounds!")
		return
	
	# Check if target cell is walkable
	if maze_grid[new_position.y][new_position.x] == 0:
		show_status("🧱 Wall! Try another path.")
		return
	
	# Valid move
	tim_position = new_position
	moves_count += 1
	
	# Mark the path Tim has taken
	mark_path_cell(tim_position)
	
	# Update Tim's visual position
	animate_tim_movement()
	
	# Update UI
	update_ui()
	
	# Check win condition
	if tim_position == end_position:
		win_game()
	else:
		show_status("Tim moved! Go to the BLUE goal.")

func animate_tim_movement():
	"""Smooth movement animation for Tim"""
	var target_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10-15
	)
	
	var tween = create_tween()
	tween.tween_property(tim_sprite, "position", target_pos, 0.25)

func update_tim_position():
	"""Update Tim's visual position on the maze"""
	var pixel_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	tim_sprite.position = pixel_pos

func mark_path_cell(pos: Vector2):
	"""Mark cells that Tim has visited"""
	if pos != Vector2(0, 0) and pos != end_position:
		maze_cells[pos.y][pos.x].color = colors.trail

func update_ui():
	"""Update all UI elements"""
	moves_label.text = "MOVES: " + str(moves_count)
	
	if timer_running:
		var current_time = Time.get_time_dict_from_system()["second"]
		game_timer = current_time - start_time
		var minutes = int(game_timer) / 60
		var seconds = int(game_timer) % 60
		timer_label.text = "TIME: %02d:%02d" % [minutes, seconds]

func show_status(message: String):
	"""Update status display"""
	status_label.text = message

func win_game():
	"""Handle win condition"""
	game_won = true
	timer_running = false
	
	show_status("🎉 LEVEL " + str(current_level) + " COMPLETE! 🎉")
	
	# Disable direction buttons
	up_button.disabled = true
	down_button.disabled = true
	left_button.disabled = true
	right_button.disabled = true
	
	# Highlight goal
	maze_cells[end_position.y][end_position.x].color = Color.GOLD
	
	# Celebration animation with responsive scaling
	var tween = create_tween()
	tween.set_loops(3)
	var current_scale = tim_sprite.scale.x
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale * 1.3, current_scale * 1.3), 0.2)
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale, current_scale), 0.2)
	
	# Auto-advance to next level after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if current_level < max_level:
		load_level(current_level + 1)
		reset_game_state()  # Reset Tim's position and game state
		start_game()
	else:
		show_status("🏆 ALL LEVELS COMPLETE! You're a maze master! 🏆")

func reset_game_state():
	"""Reset game state for new level"""
	tim_position = Vector2(0, 0)  # Reset Tim to start position
	moves_count = 0
	game_won = false
	timer_running = true
	start_time = Time.get_time_dict_from_system()["second"]
	
	# Re-enable direction buttons
	up_button.disabled = false
	down_button.disabled = false
	left_button.disabled = false
	right_button.disabled = false
	
	# Reset Tim's visual position
	update_tim_position()

func _on_reset_pressed():
	"""Reset the current level to initial state"""
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
	show_status("🔄 Level " + str(current_level) + " reset! Navigate Tim to the BLUE goal.")

func _on_main_menu_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	"""Go to game selection screen"""
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Keyboard input for accessibility
func _input(event):
	if game_won:
		return
		
	if event is InputEventKey and event.pressed:
		var direction = Vector2.ZERO
		
		match event.keycode:
			KEY_UP, KEY_W:
				direction = Vector2(0, -1)
			KEY_DOWN, KEY_S:
				direction = Vector2(0, 1)
			KEY_LEFT, KEY_A:
				direction = Vector2(-1, 0)
			KEY_RIGHT, KEY_D:
				direction = Vector2(1, 0)
			KEY_R:
				_on_reset_pressed()
				return
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var level_num = event.keycode - KEY_0
				if level_num >= 1 and level_num <= max_level:
					_on_level_selected(level_num)
				return
		
		if direction != Vector2.ZERO:
			_on_direction_button_pressed(direction)

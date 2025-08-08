extends Control

# Node references
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

# Simple game variables
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

# Responsive design
var screen_size: Vector2
var is_mobile: bool = false
var scale_factor: float = 1.0

# Simple maze layouts
var maze_layouts = {
	1: [  # Level 1 - Easy
		[1, 1, 1, 1, 1, 0, 0, 0],
		[0, 0, 0, 0, 1, 0, 1, 1],
		[0, 1, 1, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0, 0, 0, 1]
	],
	2: [  # Level 2
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 1]
	],
	3: [  # Level 3
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 0, 1, 1, 1, 0],
		[0, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 1, 1, 0, 1, 0],
		[1, 0, 0, 0, 0, 0, 1, 0],
		[1, 1, 1, 1, 1, 1, 1, 1]
	],
	4: [  # Level 4
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 1, 1, 0],
		[0, 1, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1]
	],
	5: [  # Level 5
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

# Simple colors
var colors = {
	"path": Color(0.2, 0.8, 0.4, 1),
	"wall": Color(0.8, 0.2, 0.3, 1),
	"start": Color(0.3, 1, 0.3, 1),
	"goal": Color(0.2, 0.6, 1, 1),
	"trail": Color(1, 0.8, 0.2, 1)
}

func _ready():
	print("🚀 Simple Maze Game - Starting!")
	
	# Basic setup
	detect_screen_size()
	setup_responsive_ui()
	setup_level_buttons()
	load_level(current_level)
	connect_signals()
	start_game()
	
	# Connect to screen resize events
	get_viewport().size_changed.connect(_on_screen_resized)

func detect_screen_size():
	screen_size = get_viewport().get_visible_rect().size
	is_mobile = screen_size.x < 800 or screen_size.y < 600
	var base_width = 1200.0
	scale_factor = clamp(screen_size.x / base_width, 0.5, 2.0)

func setup_responsive_ui():
	if is_mobile:
		setup_mobile_layout()
	else:
		setup_desktop_layout()

func setup_mobile_layout():
	var header_size = int(20 * scale_factor)
	if current_level_label:
		current_level_label.add_theme_font_size_override("font_size", header_size)
	if moves_label:
		moves_label.add_theme_font_size_override("font_size", header_size)
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", header_size)

func setup_desktop_layout():
	var header_size = int(24 * scale_factor)
	if current_level_label:
		current_level_label.add_theme_font_size_override("font_size", header_size)
	if moves_label:
		moves_label.add_theme_font_size_override("font_size", header_size)
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", header_size)

func _on_screen_resized():
	detect_screen_size()
	setup_responsive_ui()
	if maze_grid.size() > 0:
		setup_maze()
		setup_tim()

func setup_level_buttons():
	level_buttons = [level1_button, level2_button, level3_button, level4_button, level5_button]
	
	for i in range(level_buttons.size()):
		var button = level_buttons[i]
		if button == null:
			continue
			
		var level_num = i + 1
		button.pressed.connect(_on_level_selected.bind(level_num))
		
		# Highlight current level
		if level_num == current_level:
			button.modulate = Color(1.2, 1.2, 1.2, 1)
		else:
			button.modulate = Color(0.8, 0.8, 0.8, 1)

func load_level(level_num: int):
	if level_num < 1 or level_num > max_level:
		return
	
	current_level = level_num
	current_level_label.text = str(current_level)
	
	# Load maze layout
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

func setup_maze():
	# Clear existing maze
	for child in maze_container.get_children():
		child.queue_free()
	maze_cells.clear()
	
	# Calculate cell size
	var container_size = maze_container.size
	if container_size == Vector2.ZERO:
		container_size = Vector2(450, 450) if not is_mobile else Vector2(300, 300)
	
	var available_width = container_size.x - 20
	var available_height = container_size.y - 20
	var max_cell_size = min(available_width / grid_size.x, available_height / grid_size.y)
	cell_size = max(max_cell_size - 2, 20)
	
	# Create maze cells
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(x * (cell_size + 2) + 10, y * (cell_size + 2) + 10)
			
			# Simple color coding
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
	if tim_sprite:
		tim_sprite.queue_free()
	
	tim_sprite = Sprite2D.new()
	var tim_texture = preload("res://Assests/images/TimNeutral-removebg-preview.png")
	tim_sprite.texture = tim_texture
	
	var tim_scale = (cell_size / 200.0) * scale_factor
	tim_scale = clamp(tim_scale, 0.08, 0.25)
	tim_sprite.scale = Vector2(tim_scale, tim_scale)
	
	update_tim_position()
	maze_container.add_child(tim_sprite)

func connect_signals():
	# Simple direction button connections - direct movement
	up_button.pressed.connect(_on_move_button_pressed.bind(Vector2(0, -1)))
	down_button.pressed.connect(_on_move_button_pressed.bind(Vector2(0, 1)))
	left_button.pressed.connect(_on_move_button_pressed.bind(Vector2(-1, 0)))
	right_button.pressed.connect(_on_move_button_pressed.bind(Vector2(1, 0)))
	
	# Other buttons
	reset_button.pressed.connect(_on_reset_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if game_select_button:
		game_select_button.pressed.connect(_on_game_select_pressed)

func start_game():
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	start_time = Time.get_time_dict_from_system()["second"]
	timer_running = true
	update_ui()
	show_status("Level " + str(current_level) + " - Guide Tim to the blue goal!")

func _on_level_selected(level_num: int):
	if level_num != current_level:
		load_level(level_num)
		start_game()

func _on_move_button_pressed(direction: Vector2):
	"""Simple immediate movement when buttons are pressed"""
	if game_won:
		return
		
	var new_position = tim_position + direction
	
	# Check bounds
	if new_position.x < 0 or new_position.x >= grid_size.x or \
	   new_position.y < 0 or new_position.y >= grid_size.y:
		show_status("Can't move outside the maze!")
		return
	
	# Check if walkable
	if maze_grid[new_position.y][new_position.x] == 0:
		show_status("Wall! Try another direction.")
		return
	
	# Valid move
	tim_position = new_position
	moves_count += 1
	
	# Mark path
	mark_path_cell(tim_position)
	
	# Update Tim's position
	animate_tim_movement()
	update_ui()
	
	# Check win
	if tim_position == end_position:
		win_game()
	else:
		show_status("Keep going! Find the blue goal.")

func animate_tim_movement():
	var target_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	
	var tween = create_tween()
	tween.tween_property(tim_sprite, "position", target_pos, 0.2)

func update_tim_position():
	var pixel_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	tim_sprite.position = pixel_pos

func mark_path_cell(pos: Vector2):
	if pos != Vector2(0, 0) and pos != end_position:
		maze_cells[pos.y][pos.x].color = colors.trail

func update_ui():
	if moves_label:
		moves_label.text = "MOVES: " + str(moves_count)
	
	if timer_label and timer_running:
		var current_time = Time.get_time_dict_from_system()["second"]
		game_timer = current_time - start_time
		var minutes = int(game_timer) / 60
		var seconds = int(game_timer) % 60
		timer_label.text = "TIME: %02d:%02d" % [minutes, seconds]

func show_status(message: String):
	if status_label:
		status_label.text = message

func win_game():
	game_won = true
	timer_running = false
	
	show_status("🎉 Level " + str(current_level) + " Complete! 🎉")
	
	# Highlight goal
	maze_cells[end_position.y][end_position.x].color = Color.GOLD
	
	# Celebration animation
	var tween = create_tween()
	tween.set_loops(3)
	var current_scale = tim_sprite.scale.x
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale * 1.3, current_scale * 1.3), 0.2)
	tween.tween_property(tim_sprite, "scale", Vector2(current_scale, current_scale), 0.2)
	
	# Auto-advance after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if current_level < max_level:
		load_level(current_level + 1)
		start_game()
	else:
		show_status("🏆 All levels complete! You're amazing! 🏆")

func _on_reset_pressed():
	# Reset to start position
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	timer_running = true
	start_time = Time.get_time_dict_from_system()["second"]
	
	# Reset maze colors
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
	
	update_tim_position()
	update_ui()
	show_status("Level " + str(current_level) + " reset! Guide Tim to the blue goal!")

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Simple keyboard input
func _input(event):
	if game_won:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				_on_move_button_pressed(Vector2(0, -1))
			KEY_DOWN, KEY_S:
				_on_move_button_pressed(Vector2(0, 1))
			KEY_LEFT, KEY_A:
				_on_move_button_pressed(Vector2(-1, 0))
			KEY_RIGHT, KEY_D:
				_on_move_button_pressed(Vector2(1, 0))
			KEY_R:
				_on_reset_pressed()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var level_num = event.keycode - KEY_0
				if level_num >= 1 and level_num <= max_level:
					_on_level_selected(level_num)

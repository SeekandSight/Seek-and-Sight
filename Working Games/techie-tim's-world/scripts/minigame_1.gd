extends Control

# Node references - only what we need
@onready var maze_container = $MainContainer/GameContent/LeftPanel/MazeContainer
@onready var moves_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/MovesLabel
@onready var timer_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/TimerLabel
@onready var status_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/StatusLabel
@onready var current_level_label = $MainContainer/Header/LevelContainer/CurrentLevelLabel

# Game variables
var current_level = 1
var max_level = 5
var highest_unlocked_level = 1  # NEW: Track highest unlocked level
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
var timer_running = false

# Level buttons - store references for enabling/disabling
var level_buttons = []

# Maze layouts
var maze_layouts = {
	1: [
		[1, 1, 1, 1, 1, 0, 0, 0],
		[0, 0, 0, 0, 1, 0, 1, 1],
		[0, 1, 1, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0, 0, 0, 1]
	],
	2: [
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 1]
	],
	3: [
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 0, 1, 1, 1, 0],
		[0, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 0, 1, 0],
		[1, 0, 1, 1, 1, 0, 1, 0],
		[1, 0, 0, 0, 0, 0, 1, 0],
		[1, 1, 1, 1, 1, 1, 1, 1]
	],
	4: [
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 0, 1, 0],
		[0, 1, 0, 0, 1, 1, 1, 0],
		[0, 1, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1]
	],
	5: [
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

# Colors
var colors = {
	"path": Color(0.2, 0.8, 0.4, 1),
	"wall": Color(0.8, 0.2, 0.3, 1),
	"start": Color(0.3, 1, 0.3, 1),
	"goal": Color(0.2, 0.6, 1, 1),
	"trail": Color(1, 0.8, 0.2, 1)
}

func _ready():
	print("🚀 Maze Game Starting!")
	load_level(current_level)
	start_game()
	
	# Wait a moment for all nodes to be ready, then connect buttons
	await get_tree().process_frame
	connect_buttons_simple()
	setup_level_buttons()  # NEW: Setup level button references and states

# NEW: Setup level button references and update their states
func setup_level_buttons():
	print("🔧 Setting up level buttons...")
	
	var level_container = get_node_or_null("MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/LevelButtons/LevelButtonsContainer")
	
	if not level_container:
		print("❌ Level buttons container not found!")
		return
	
	# Store references to level buttons
	level_buttons.clear()
	for i in range(1, max_level + 1):
		var button = level_container.get_node_or_null("Level" + str(i) + "Button")
		if button:
			level_buttons.append(button)
			print("Found level button: ", i)
		else:
			print("❌ Level button ", i, " not found!")
			level_buttons.append(null)
	
	update_level_buttons()

# NEW: Update level button states based on progression
func update_level_buttons():
	print("🔄 Updating level button states...")
	print("Highest unlocked level: ", highest_unlocked_level)
	
	for i in range(level_buttons.size()):
		var button = level_buttons[i]
		if button == null:
			continue
			
		var level_num = i + 1
		
		if level_num <= highest_unlocked_level:
			# Level is unlocked
			button.disabled = false
			button.modulate = Color(1, 1, 1, 1)  # Normal color
			if level_num == current_level:
				button.text = str(level_num) # Mark current level
			else:
				button.text = str(level_num)
		else:
			# Level is locked
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Grayed out
			button.text = str(level_num) + " 🔒"

func connect_buttons_simple():
	print("🔧 Connecting buttons manually...")
	
	# Get the GameButtons container
	var buttons_container = get_node_or_null("MainContainer/GameContent/RightPanel/ControlsPanel/ControlsContainer/GameButtons")
	
	if not buttons_container:
		print("❌ GameButtons container not found!")
		return
	
	# Find and connect each button by going through all children
	for child in buttons_container.get_children():
		if child is Button:
			var button_text = child.text.to_upper()
			print("Found button: ", child.name, " with text: ", child.text)
			
			# Connect based on button text
			if "RESET" in button_text or "SYSTEM RESET" in button_text:
				child.pressed.connect(_on_reset_pressed)
				print("✅ Connected RESET button")
				
			elif "MAIN" in button_text or "TERMINAL" in button_text or "NEXT" in button_text:
				child.pressed.connect(_on_main_menu_pressed) 
				print("✅ Connected NEXT GAME button")
				
			elif "GAME SELECT" in button_text or "SELECT" in button_text:
				child.pressed.connect(_on_game_select_pressed)
				print("✅ Connected GAME SELECT button")

func load_level(level_num: int):
	if level_num < 1 or level_num > max_level:
		return
	
	current_level = level_num
	current_level_label.text = str(current_level)
	maze_grid = maze_layouts[current_level].duplicate(true)
	setup_maze()
	setup_tim()
	update_level_buttons()  # NEW: Update button states when level changes

func setup_maze():
	# Clear existing maze
	for child in maze_container.get_children():
		child.queue_free()
	maze_cells.clear()
	
	# Calculate cell size
	var container_size = maze_container.size
	if container_size == Vector2.ZERO:
		container_size = Vector2(450, 450)
	
	var available_size = container_size - Vector2(20, 20)
	cell_size = min(available_size.x / grid_size.x, available_size.y / grid_size.y) - 2
	cell_size = max(cell_size, 20)
	
	# Create maze cells
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(x * (cell_size + 2) + 10, y * (cell_size + 2) + 10)
			
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
	tim_sprite.scale = Vector2(0.15, 0.15)
	
	update_tim_position()
	maze_container.add_child(tim_sprite)

func start_game():
	tim_position = Vector2(0, 0)
	moves_count = 0
	game_won = false
	start_time = Time.get_time_dict_from_system()["second"]
	timer_running = true
	
	if tim_sprite:
		update_tim_position()
	
	update_ui()
	show_status("Level " + str(current_level) + " - Guide Tim to the blue goal!")

func _on_level_selected(level_num: int):
	print("Level selected: ", level_num)
	
	# NEW: Check if level is unlocked
	if level_num > highest_unlocked_level:
		show_status("🔒 Level " + str(level_num) + " is locked! Complete previous levels first.")
		return
	
	if level_num != current_level:
		load_level(level_num)
		start_game()

func _on_move_button_pressed(direction: Vector2):
	print("Move: ", direction)
	
	if game_won:
		return
		
	var new_position = tim_position + direction
	
	# Check bounds
	if new_position.x < 0 or new_position.x >= grid_size.x or new_position.y < 0 or new_position.y >= grid_size.y:
		show_status("Can't move outside the maze!")
		return
	
	# Check if walkable
	if maze_grid[new_position.y][new_position.x] == 0:
		show_status("Wall! Try another direction.")
		return
	
	# Valid move
	tim_position = new_position
	moves_count += 1
	
	# Mark trail
	if tim_position != Vector2(0, 0) and tim_position != end_position:
		maze_cells[tim_position.y][tim_position.x].color = colors.trail
	
	# Move Tim
	var target_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	var tween = create_tween()
	tween.tween_property(tim_sprite, "position", target_pos, 0.2)
	
	update_ui()
	
	# Check win
	if tim_position == end_position:
		win_game()
	else:
		show_status("Keep going! Find the blue goal.")

func update_tim_position():
	if not tim_sprite:
		return
		
	var pixel_pos = Vector2(
		tim_position.x * (cell_size + 2) + cell_size/2 + 10,
		tim_position.y * (cell_size + 2) + cell_size/2 + 10 - 15
	)
	tim_sprite.position = pixel_pos

func update_ui():
	if moves_label:
		moves_label.text = "MOVES: " + str(moves_count)
	
	if timer_label and timer_running:
		var current_time = Time.get_time_dict_from_system()["second"]
		var elapsed = current_time - start_time
		var minutes = int(elapsed) / 60
		var seconds = int(elapsed) % 60
		timer_label.text = "TIME: %02d:%02d" % [minutes, seconds]

func show_status(message: String):
	if status_label:
		status_label.text = message

func win_game():
	game_won = true
	timer_running = false
	
	# NEW: Unlock next level when current level is completed
	if current_level == highest_unlocked_level and current_level < max_level:
		highest_unlocked_level = current_level + 1
		print("🔓 Unlocked level: ", highest_unlocked_level)
		update_level_buttons()
	
	show_status("🎉 Level " + str(current_level) + " Complete! 🎉")
	maze_cells[end_position.y][end_position.x].color = Color.GOLD
	
	# Celebration animation
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(tim_sprite, "scale", Vector2(0.2, 0.2), 0.2)
	tween.tween_property(tim_sprite, "scale", Vector2(0.15, 0.15), 0.2)
	
	# Auto-advance after 2 seconds, but only if next level is unlocked
	await get_tree().create_timer(2.0).timeout
	if current_level < max_level and current_level + 1 <= highest_unlocked_level:
		load_level(current_level + 1)
		start_game()
	else:
		if current_level == max_level:
			show_status("🏆 All levels complete!")
		else:
			show_status("🎉 Level complete! Select another level to play.")

func _on_reset_pressed():
	print("🔥 RESET BUTTON CLICKED!")
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
	show_status("Level " + str(current_level) + " reset!")

func _on_main_menu_pressed():
	print("🔥 NEXT GAME BUTTON CLICKED!")
	print("Navigating to minigame_2...")
	if ResourceLoader.exists("res://Scenes/minigame_2.tscn"):
		get_tree().change_scene_to_file("res://Scenes/minigame_2.tscn")
	else:
		print("❌ minigame_2.tscn not found!")
		# Fallback - go to main menu if minigame_2 doesn't exist
		if ResourceLoader.exists("res://Scenes/main_menu.tscn"):
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	print("🔥 GAME SELECT BUTTON CLICKED!")
	print("Navigating to game_selection...")
	if ResourceLoader.exists("res://Scenes/game_selection.tscn"):
		get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")
	else:
		print("❌ game_selection.tscn not found!")
		# Fallback - go to main menu if game_selection doesn't exist
		if ResourceLoader.exists("res://Scenes/main_menu.tscn"):
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# Keyboard input only - no complicated mouse backup
func _input(event):
	if game_won or not event is InputEventKey or not event.pressed:
		return
		
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
		KEY_N:  # N for Next Game
			_on_main_menu_pressed()
		KEY_G:  # G for Game Select
			_on_game_select_pressed()

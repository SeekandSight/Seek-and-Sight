extends Control

# Animal Match Game - Working with your existing minigame1.tscn structure
# Designed for children with learning disabilities

# Game state variables
var game_active = false
var current_animals = []
var matched_pairs = 0
var total_pairs = 4  # Show 4-5 animals at a time
var current_set = 0
var all_animal_sets = []

# Audio player for animal sounds
var animal_audio: AudioStreamPlayer

# UI References - matching your exact scene structure
@onready var animals_panel = $Panel/VBoxContainer/Panel
@onready var names_panel = $Panel/VBoxContainer2/Panel
@onready var instructions_panel = $Panel/VBoxContainer3/Panel

# Navigation buttons from your scene
@onready var main_menu_btn = $Panel/VBoxContainer3/VBoxContainer/StartButton
@onready var game_selection_btn = $Panel/VBoxContainer3/VBoxContainer/InstructionButton
@onready var settings_btn = $Panel/VBoxContainer3/VBoxContainer/SettingButton

# Animal data with correct file paths
var animal_data = {
	"CAT": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/CAT.wav", "image": "res://Assets/animals/cat.png"},
	"DOG": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/DOG.wav", "image": "res://Assets/animals/dog.png"},
	"COW": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/COW.wav", "image": "res://Assets/animals/cow.png"},
	"DUCK": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/DUCK.wav", "image": "res://Assets/animals/duck.png"},
	"FISH": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/FISH.wav", "image": "res://Assets/animals/fish.png"},
	"GOAT": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/GOAT.wav", "image": "res://Assets/animals/goat.png"},
	"HORSE": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/HORSE.wav", "image": "res://Assets/animals/horse.png"},
	"LION": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/LION.wav", "image": "res://Assets/animals/lion.png"},
	"PIG": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/PIG.wav", "image": "res://Assets/animals/pig.png"},
	"RABBIT": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/RABBIT.wav", "image": "res://Assets/animals/rabbit.png"},
	"SHEEP": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/SHEEP.wav", "image": "res://Assets/animals/sheep.png"},
	"CHICKEN": {"audio": "res://Assets/Audio Lines/Sight Words/Animals/CHICKEN.wav", "image": "res://Assets/animals/chicken.png"}
}

# Drag and drop variables
var dragging_item = null
var drag_offset = Vector2()

func _ready():
	setup_audio_player()
	setup_game_interface()
	connect_navigation_buttons()

func setup_audio_player():
	# Create audio player for animal sounds (accessibility feature)
	animal_audio = AudioStreamPlayer.new()
	add_child(animal_audio)

func setup_game_interface():
	# Setup beautiful instructions in the instructions panel
	setup_instructions()
	
	# Add Start Game button
	add_start_game_button()

func setup_instructions():
	# Clear the instructions panel and add our content
	for child in instructions_panel.get_children():
		if child.name == "VBoxContainer":
			continue  # Keep the navigation buttons
		child.queue_free()
	
	# Create instruction container
	var instruction_container = VBoxContainer.new()
	instruction_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_container.add_theme_constant_override("separation", 8)
	instructions_panel.add_child(instruction_container)
	
	# Move the instruction container before the button container
	instructions_panel.move_child(instruction_container, 0)
	
	# Instruction title
	var title = Label.new()
	title.text = "How to Play Animal Match"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8, 1.0))
	instruction_container.add_child(title)
	
	# Game instructions
	var instructions_text = """1. Click 'Start Game' below
2. Look at animal pictures on left  
3. Click animals to hear their names
4. Drag animals to matching names
5. Match all animals to win!

Tips for Success:
• Listen to sounds for help
• Take your time - no rush!
• Try again if you make a mistake
• You're doing great!"""
	
	var instruction_label = Label.new()
	instruction_label.text = instructions_text
	instruction_label.add_theme_font_size_override("font_size", 12)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	instruction_container.add_child(instruction_label)

func add_start_game_button():
	# Add Start Game button to the existing button container
	var button_container = $Panel/VBoxContainer3/VBoxContainer
	
	var start_button = Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(190, 45)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.add_theme_color_override("font_color", Color.BLACK)
	
	# Style the start button with green color
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.8, 0.3, 1.0)  # Green
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
	
	# Move start button to the top
	button_container.move_child(start_button, 0)

func connect_navigation_buttons():
	# Connect existing navigation buttons with debug output
	print("=== CONNECTING ANIMAL MATCH NAVIGATION ===")
	
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
		print("Connected Main Menu button for Animal Match")
	else:
		print("Main Menu button not found in Animal Match")
		
	if game_selection_btn:
		game_selection_btn.pressed.connect(_on_game_selection_pressed)
		print("Connected Game Selection button for Animal Match")
	else:
		print("Game Selection button not found in Animal Match")
		
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
		print("Connected Settings button for Animal Match")
	else:
		print("Settings button not found in Animal Match")
	
	print("========================================")

func start_game():
	if game_active:
		return
		
	game_active = true
	matched_pairs = 0  # Reset for each set
	
	# Select animals for this round
	select_animals_for_round()
	create_game_elements()
	
	# Update start button
	var start_button = $Panel/VBoxContainer3/VBoxContainer/StartGameButton
	start_button.text = "Playing..."
	start_button.disabled = true

func select_animals_for_round():
	# Create sets of 4-5 animals each
	if all_animal_sets.is_empty():
		var all_animals = animal_data.keys()
		all_animals.shuffle()
		
		# Split into sets of 4-5 animals each
		var set_sizes = [4, 5, 4, 5]  # Alternate between 4 and 5 animals
		var current_index = 0
		var set_number = 0
		
		while current_index < all_animals.size():
			var set_size = set_sizes[set_number % set_sizes.size()]
			var end_index = min(current_index + set_size, all_animals.size())
			var animal_set = all_animals.slice(current_index, end_index)
			
			if animal_set.size() > 0:
				all_animal_sets.append(animal_set)
			
			current_index = end_index
			set_number += 1
	
	# Get current set of animals
	if current_set < all_animal_sets.size():
		current_animals = all_animal_sets[current_set]
		total_pairs = current_animals.size()
	else:
		# All sets completed, create new shuffled sets
		current_set = 0
		all_animal_sets.clear()
		select_animals_for_round()  # Recursively create new sets

func create_game_elements():
	# Clear both panels
	clear_game_panels()
	
	# Determine grid layout based on number of animals
	var columns = 2 if total_pairs <= 4 else 3
	
	# Create animals grid in left panel
	var animals_grid = GridContainer.new()
	animals_grid.columns = columns
	animals_grid.add_theme_constant_override("h_separation", 12)
	animals_grid.add_theme_constant_override("v_separation", 12)
	animals_grid.position = Vector2(10, 10)
	animals_grid.size = animals_panel.size - Vector2(20, 20)
	animals_panel.add_child(animals_grid)
	
	# Create names grid in right panel
	var names_grid = GridContainer.new()
	names_grid.columns = columns
	names_grid.add_theme_constant_override("h_separation", 12)
	names_grid.add_theme_constant_override("v_separation", 12)
	names_grid.position = Vector2(10, 10)
	names_grid.size = names_panel.size - Vector2(20, 20)
	names_panel.add_child(names_grid)
	
	# Add animal buttons
	for i in range(current_animals.size()):
		var animal_name = current_animals[i]
		var animal_button = create_animal_button(animal_name)
		animals_grid.add_child(animal_button)
	
	# Add name targets (shuffled for challenge)
	var shuffled_names = current_animals.duplicate()
	shuffled_names.shuffle()
	
	for animal_name in shuffled_names:
		var name_target = create_name_target(animal_name)
		names_grid.add_child(name_target)

func create_animal_button(animal_name: String) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 80)  # Square size for perfect circle
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Try to load animal image
	var image_path = animal_data[animal_name]["image"]
	if ResourceLoader.exists(image_path):
		var texture = load(image_path) as Texture2D
		if texture:
			button.icon = texture
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			# Don't show text when we have image
			button.text = ""
		else:
			# Only show text if no image available
			button.text = animal_name
			button.add_theme_font_size_override("font_size", 14)
	else:
		# Only show text if no image available
		button.text = animal_name
		button.add_theme_font_size_override("font_size", 14)
	
	button.set_meta("animal_name", animal_name)
	
	# Circular styling - large corner radius to make it round
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	style.corner_radius_top_left = 40  # Half of button size for perfect circle
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_left = 40
	style.corner_radius_bottom_right = 40
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 0.2)  # Slight white highlight on hover
	hover_style.corner_radius_top_left = 40
	hover_style.corner_radius_top_right = 40
	hover_style.corner_radius_bottom_left = 40
	hover_style.corner_radius_bottom_right = 40
	
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect signals with debug output
	button.pressed.connect(_on_animal_clicked.bind(animal_name))
	button.gui_input.connect(_on_animal_input.bind(button))
	print("Connected signals for animal: ", animal_name)  # Debug
	
	return button

func create_name_target(animal_name: String) -> Label:
	var target_label = Label.new()
	target_label.text = animal_name.capitalize()
	target_label.custom_minimum_size = Vector2(90, 80)
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 18)
	target_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Make text bold
	var font_variation = target_label.get_theme_font("font")
	if font_variation:
		target_label.add_theme_font_size_override("font_size", 20)
	
	# Add subtle background for better readability
	var background_style = StyleBoxFlat.new()
	background_style.bg_color = Color(0, 0, 0, 0.3)  # Semi-transparent dark background
	background_style.corner_radius_top_left = 8
	background_style.corner_radius_top_right = 8
	background_style.corner_radius_bottom_left = 8
	background_style.corner_radius_bottom_right = 8
	target_label.add_theme_stylebox_override("normal", background_style)
	
	# Store metadata for game logic
	target_label.set_meta("animal_name", animal_name)
	target_label.set_meta("matched", false)
	target_label.set_meta("original_style", background_style)
	
	return target_label

func _on_animal_clicked(animal_name: String):
	# Play animal sound for accessibility
	play_animal_sound(animal_name)

func play_animal_sound(animal_name: String):
	var audio_path = animal_data[animal_name]["audio"]
	if ResourceLoader.exists(audio_path):
		var audio_stream = load(audio_path) as AudioStream
		if audio_stream:
			animal_audio.stream = audio_stream
			animal_audio.play()

func _on_animal_input(event: InputEvent, button: Button):
	if not game_active:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Play sound immediately on mouse press (before drag starts)
				var animal_name = button.get_meta("animal_name")
				print("Mouse pressed on animal: ", animal_name)  # Debug
				play_animal_sound(animal_name)
				
				# Start drag after sound
				start_drag(button, event.global_position)
			else:
				stop_drag(event.global_position)
	elif event is InputEventMouseMotion and dragging_item == button:
		update_drag(event.global_position)

func start_drag(button: Button, mouse_pos: Vector2):
	dragging_item = button
	drag_offset = button.global_position - mouse_pos
	
	# Store the parent grid and the button's index in that grid
	var parent_grid = button.get_parent()
	if parent_grid:
		var button_index = button.get_index()
		button.set_meta("original_parent_grid", parent_grid)
		button.set_meta("original_grid_index", button_index)
	
	# Visual feedback for dragging
	button.z_index = 100
	button.modulate = Color(1.0, 1.0, 1.0, 0.8)

func update_drag(mouse_pos: Vector2):
	if dragging_item:
		dragging_item.global_position = mouse_pos + drag_offset

func stop_drag(mouse_pos: Vector2):
	if not dragging_item or not is_instance_valid(dragging_item):
		dragging_item = null
		return
	
	var dropped_on_target = false
	
	# Check all name targets (Labels)
	var names_grid = names_panel.get_child(0)
	if names_grid and is_instance_valid(names_grid):
		for target in names_grid.get_children():
			if target is Label and is_instance_valid(target):
				var target_rect = Rect2(target.global_position, target.size)
				if target_rect.has_point(mouse_pos):
					handle_drop(target)
					dropped_on_target = true
					break
	
	if not dropped_on_target:
		return_to_position()
	
	# Reset visual state safely
	if dragging_item and is_instance_valid(dragging_item):
		dragging_item.z_index = 0
		dragging_item.modulate = Color.WHITE
	
	dragging_item = null

func handle_drop(target: Label):
	var animal_name = dragging_item.get_meta("animal_name")
	var target_name = target.get_meta("animal_name")
	var already_matched = target.get_meta("matched")
	
	if animal_name == target_name and not already_matched:
		correct_match(target)
	else:
		incorrect_match(target)

func correct_match(target: Label):
	target.set_meta("matched", true)
	matched_pairs += 1
	
	# Beautiful success visual effects for the label
	var success_style = StyleBoxFlat.new()
	success_style.bg_color = Color(0.2, 0.8, 0.2, 0.7)  # Green highlight
	success_style.corner_radius_top_left = 8
	success_style.corner_radius_top_right = 8
	success_style.corner_radius_bottom_left = 8
	success_style.corner_radius_bottom_right = 8
	success_style.border_width_left = 3
	success_style.border_width_right = 3
	success_style.border_width_top = 3
	success_style.border_width_bottom = 3
	success_style.border_color = Color(0.1, 0.6, 0.1, 1.0)
	target.add_theme_stylebox_override("normal", success_style)
	
	# Make text larger and bolder when matched
	target.add_theme_font_size_override("font_size", 24)
	target.add_theme_color_override("font_color", Color.WHITE)
	
	# Celebration animation for the text
	var tween = create_tween()
	tween.tween_property(target, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Hide matched animal
	dragging_item.visible = false
	
	# REMOVED: No sound plays when correct match is made
	# This allows sounds only when clicking to learn, not when matching
	
	# Check completion
	if matched_pairs >= total_pairs:
		game_completed()

func incorrect_match(target: Label):
	if not dragging_item or not is_instance_valid(dragging_item):
		return
	
	# Visual feedback for wrong match on both animal and target
	var tween = create_tween()
	
	# Red flash effect on the dragged animal
	if dragging_item and is_instance_valid(dragging_item):
		tween.parallel().tween_property(dragging_item, "modulate", Color(1.0, 0.3, 0.3), 0.15)
		tween.parallel().tween_property(dragging_item, "modulate", Color.WHITE, 0.15)
	
	# Red flash effect on the target label
	if target and is_instance_valid(target):
		var wrong_style = StyleBoxFlat.new()
		wrong_style.bg_color = Color(0.8, 0.2, 0.2, 0.6)  # Red highlight
		wrong_style.corner_radius_top_left = 8
		wrong_style.corner_radius_top_right = 8
		wrong_style.corner_radius_bottom_left = 8
		wrong_style.corner_radius_bottom_right = 8
		target.add_theme_stylebox_override("normal", wrong_style)
		
		# Store current position before shake effect
		var current_target_position = target.position
		tween.parallel().tween_property(target, "position", current_target_position + Vector2(5, 0), 0.1)
		tween.parallel().tween_property(target, "position", current_target_position - Vector2(5, 0), 0.1)
		tween.parallel().tween_property(target, "position", current_target_position, 0.1)
	
	# Return to original style after effect
	if target and is_instance_valid(target):
		var original_style = target.get_meta("original_style")
		if original_style:
			target.add_theme_stylebox_override("normal", original_style)
	
	# Return animal to original position
	return_to_position()

func return_to_position():
	if not dragging_item or not is_instance_valid(dragging_item):
		return
	
	# Get stored original information
	var original_parent_grid = dragging_item.get_meta("original_parent_grid")
	var original_index = dragging_item.get_meta("original_grid_index")
	
	print("Returning animal to original position")  # Debug output
	
	if original_parent_grid and is_instance_valid(original_parent_grid):
		# Remove from current parent (scene root)
		if dragging_item.get_parent():
			dragging_item.get_parent().remove_child(dragging_item)
		
		# Add back to original grid
		original_parent_grid.add_child(dragging_item)
		
		# Move to correct position in grid
		if original_index >= 0 and original_index < original_parent_grid.get_child_count():
			original_parent_grid.move_child(dragging_item, original_index)
		
		print("Animal returned to grid position: ", original_index)  # Debug output
	
	# Reset visual state
	dragging_item.modulate = Color.WHITE
	dragging_item.z_index = 0

func game_completed():
	game_active = false
	current_set += 1
	
	# Check if there are more sets to play
	if current_set < all_animal_sets.size():
		var next_set_size = all_animal_sets[current_set].size()
		
		# Show Next Set button
		var start_button = $Panel/VBoxContainer3/VBoxContainer/StartGameButton
		start_button.text = "Next Set (" + str(next_set_size) + " animals)"
		start_button.disabled = false
		
		# Celebration effect for completing a set
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0), 0.3)
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		
	else:
		# All sets completed - offer to play with new mixed sets
		update_instructions("Congratulations! You completed ALL sets!\nYou're an Animal Matching Champion!\nClick 'New Game' for more animals!")
		
		# Reset for a completely new game with new shuffles
		all_animal_sets.clear()
		current_set = 0
		
		var start_button = $Panel/VBoxContainer3/VBoxContainer/StartGameButton
		start_button.text = "New Game"
		start_button.disabled = false
		
		# Big celebration effect for completing everything
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.4, 1.4, 1.1), 0.4)
		tween.tween_property(self, "modulate", Color.WHITE, 0.4)

func update_instructions(text: String):
	# Find and update the instruction text
	var instruction_container = instructions_panel.get_child(0)
	if instruction_container and instruction_container is VBoxContainer:
		for child in instruction_container.get_children():
			if child is Label and "Click 'Start Game'" in child.text:
				child.text = text
				break

func clear_game_panels():
	# Clear animals panel
	for child in animals_panel.get_children():
		child.queue_free()
	
	# Clear names panel  
	for child in names_panel.get_children():
		child.queue_free()

# Navigation handlers - FIXED PATHS
func _on_main_menu_pressed():
	print("Animal Match: Main Menu button pressed")
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_selection_pressed():
	print("Animal Match: Game Selection button pressed")
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

func _on_settings_pressed():
	print("Animal Match: Settings button pressed")
	# Add settings functionality here later

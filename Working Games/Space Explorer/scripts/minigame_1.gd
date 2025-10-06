extends Control

# References to scene nodes
@onready var solar_system_panel = $VBoxContainer/Panel
@onready var words_panel = $VBoxContainer3/Panel
@onready var main_menu_button = $VBoxContainer2/VBoxContainer/VBoxContainer/MainMenuButton
@onready var game_select_button = $VBoxContainer2/VBoxContainer/VBoxContainer/GameSelectButton
@onready var settings_button = $VBoxContainer2/VBoxContainer/VBoxContainer/SettingsButton
@onready var instructions_panel = $VBoxContainer2/Panel

# Game data - Planet to Word mappings
var planet_data = {
	"Sun": "Brightest Star",
	"Mercury": "Smallest Planet",
	"Venus": "Hottest Planet",
	"Earth": "Our Home",
	"Mars": "Red Planet",
	"Jupiter": "Largest Planet",
	"Saturn": "Planet with Rings",
	"Neptune": "Farthest Planet"
}

# Motivational messages
var wrong_messages = [
	"Oops! Not quite! Try again!",
	"Almost there! Give it another shot!",
	"Keep trying, space explorer!",
	"Don't give up! You can do it!",
	"Nice try! Think about it again!",
	"So close! Try once more!"
]

var correct_messages = [
	"Amazing! You got it!",
	"Perfect match! Great job!",
	"Excellent work, astronaut! 🚀",
	"Wonderful! Keep going!",
	"Fantastic! You're doing great!",
	"Brilliant! Well done!"
]

# Current game state
var current_planets = []
var current_words = []
var score = 0
var total_matches = 0
var alert_label = null

# Planet and word sizes
const PLANET_SIZE = Vector2(80, 80)
const WORD_CARD_SIZE = Vector2(180, 45)

# Draggable planet script as inner class
class DraggablePlanet extends Control:
	var dragging = false
	var drag_offset = Vector2.ZERO
	var original_position = Vector2.ZERO
	var original_parent = null
	
	func _ready():
		original_position = position
		original_parent = get_parent()
	
	func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_offset = get_global_mouse_position() - global_position
					get_parent().move_child(self, get_parent().get_child_count() - 1)
				else:
					dragging = false
					check_drop()
	
	func _process(_delta):
		if dragging:
			global_position = get_global_mouse_position() - drag_offset
	
	func check_drop():
		var mouse_pos = get_global_mouse_position()
		var game = get_tree().current_scene
		
		for word_zone in game.current_words:
			if word_zone.get_global_rect().has_point(mouse_pos):
				var planet_name = get_meta("planet_name")
				var matched = game.check_match(planet_name, word_zone)
				
				if matched:
					return
				else:
					return_to_start()
					return
		
		return_to_start()
	
	func return_to_start():
		var tween = create_tween()
		tween.tween_property(self, "position", original_position, 0.3)

func _ready():
	# Connect button signals
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	game_select_button.pressed.connect(_on_game_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	
	# Create alert label
	create_alert_label()
	
	# Add instructions to the panel
	create_instructions()
	
	# Start the game
	setup_game()

func create_alert_label():
	"""Create a floating alert label for feedback messages"""
	alert_label = Label.new()
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_size_override("font_size", 28)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Position at top center of screen
	alert_label.position = Vector2(get_viewport_rect().size.x / 2 - 200, 100)
	alert_label.custom_minimum_size = Vector2(400, 60)
	alert_label.visible = false
	
	# Add outline effect
	alert_label.add_theme_color_override("font_outline_color", Color.BLACK)
	alert_label.add_theme_constant_override("outline_size", 3)
	
	add_child(alert_label)

func create_instructions():
	"""Add game instructions to the instructions panel"""
	# Clear existing content
	for child in instructions_panel.get_children():
		child.queue_free()
	
	var instructions_text = """HOW TO PLAY:

1. Look at the planets in the 
   Solar System area above

2. Read the descriptions in 
   the Words area below

3. Drag each planet to its 
   matching description

4. Drop it on the correct word

✅ GREEN = Correct!
❌ RED = Try again!

Match all 8 planets to win!"""
	
	var instructions_label = Label.new()
	instructions_label.text = instructions_text
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	instructions_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	instructions_label.add_theme_font_size_override("font_size", 14)
	instructions_label.add_theme_color_override("font_color", Color.WHITE)
	instructions_label.position = Vector2(10, 10)
	instructions_label.custom_minimum_size = Vector2(230, 220)
	
	instructions_panel.add_child(instructions_label)

func show_alert(message: String, is_correct: bool):
	"""Display a motivational alert message"""
	alert_label.text = message
	
	if is_correct:
		alert_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))  # Bright green
	else:
		alert_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))  # Orange
	
	alert_label.visible = true
	
	# Animate the alert
	alert_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(alert_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2)
	tween.tween_property(alert_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): alert_label.visible = false)

func setup_game():
	"""Initialize the game with planets and words"""
	clear_game_area()
	
	# Use all 8 planets
	var all_planets = planet_data.keys()
	all_planets.shuffle()
	
	create_planets(all_planets)
	create_words(all_planets)
	
	total_matches = all_planets.size()
	score = 0

func clear_game_area():
	"""Remove all existing planets and words"""
	for child in solar_system_panel.get_children():
		child.queue_free()
	for child in words_panel.get_children():
		child.queue_free()
	current_planets.clear()
	current_words.clear()

func create_planets(planet_names: Array):
	"""Create draggable planet objects in 2 rows"""
	var spacing_x = 150
	var spacing_y = 50
	var start_x = 30
	var start_y = 20
	var planets_per_row = 4
	
	for i in range(planet_names.size()):
		var row = i / planets_per_row
		var col = i % planets_per_row
		
		var planet = create_planet_node(planet_names[i])
		var x_pos = start_x + col * (PLANET_SIZE.x + spacing_x)
		var y_pos = start_y + row * (PLANET_SIZE.y + spacing_y + 20)
		
		planet.position = Vector2(x_pos, y_pos)
		solar_system_panel.add_child(planet)
		current_planets.append(planet)

func create_planet_node(planet_name: String) -> Control:
	"""Create a single draggable planet"""
	var planet_container = DraggablePlanet.new()
	planet_container.custom_minimum_size = PLANET_SIZE
	planet_container.set_meta("planet_name", planet_name)
	
	# Add planet image
	var planet_sprite = TextureRect.new()
	planet_sprite.name = "PlanetSprite"
	planet_sprite.custom_minimum_size = PLANET_SIZE
	planet_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	planet_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load planet texture
	var texture_path = "res://Assets/planets-bg/" + planet_name.to_lower() + ".png"
	if ResourceLoader.exists(texture_path):
		planet_sprite.texture = load(texture_path)
	else:
		# Placeholder colored panel if image doesn't exist yet
		var placeholder = Panel.new()
		placeholder.custom_minimum_size = PLANET_SIZE
		placeholder.modulate = get_planet_color(planet_name)
		planet_container.add_child(placeholder)
	
	if planet_sprite.texture:
		planet_container.add_child(planet_sprite)
	
	# Add planet name label
	var label = Label.new()
	label.text = planet_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, PLANET_SIZE.y + 2)
	label.custom_minimum_size = Vector2(PLANET_SIZE.x, 18)
	label.add_theme_font_size_override("font_size", 12)
	planet_container.add_child(label)
	
	return planet_container

func create_words(planet_names: Array):
	"""Create word drop zones in 2 rows"""
	var words = []
	for planet in planet_names:
		words.append(planet_data[planet])
	
	words.shuffle()
	
	var spacing_x = 15
	var spacing_y = 10
	var start_x = 30
	var start_y = 15
	var words_per_row = 4
	
	for i in range(words.size()):
		var row = i / words_per_row
		var col = i % words_per_row
		
		var word_zone = create_word_zone(words[i], planet_names[planet_names.find(get_planet_for_word(words[i]))])
		var x_pos = start_x + col * (WORD_CARD_SIZE.x + spacing_x)
		var y_pos = start_y + row * (WORD_CARD_SIZE.y + spacing_y)
		
		word_zone.position = Vector2(x_pos, y_pos)
		words_panel.add_child(word_zone)
		current_words.append(word_zone)

func get_planet_for_word(word: String) -> String:
	"""Get the planet name that matches a word"""
	for planet in planet_data.keys():
		if planet_data[planet] == word:
			return planet
	return ""

func create_word_zone(word: String, correct_planet: String) -> Panel:
	"""Create a drop zone for words"""
	var word_container = Panel.new()
	word_container.custom_minimum_size = WORD_CARD_SIZE
	word_container.set_meta("word", word)
	word_container.set_meta("correct_planet", correct_planet)
	word_container.set_meta("matched", false)
	
	# Style the word card
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.5, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.6, 0.9, 1.0)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	word_container.add_theme_stylebox_override("panel", style_box)
	
	# Add word label
	var label = Label.new()
	label.text = word
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = WORD_CARD_SIZE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	word_container.add_child(label)
	
	return word_container

func get_planet_color(planet_name: String) -> Color:
	"""Get placeholder colors for planets"""
	match planet_name:
		"Sun": return Color.YELLOW
		"Mercury": return Color.GRAY
		"Venus": return Color.ORANGE
		"Earth": return Color.BLUE
		"Mars": return Color.RED
		"Jupiter": return Color.SADDLE_BROWN
		"Saturn": return Color.SANDY_BROWN
		"Neptune": return Color.DEEP_SKY_BLUE
		_: return Color.WHITE

func check_match(planet_name: String, drop_zone: Panel) -> bool:
	"""Check if planet matches the word"""
	var correct_planet = drop_zone.get_meta("correct_planet")
	var is_matched = drop_zone.get_meta("matched")
	
	if is_matched:
		return false
	
	if planet_name == correct_planet:
		# Correct match!
		drop_zone.set_meta("matched", true)
		show_feedback(drop_zone, true)
		score += 1
		
		# Show motivational message
		var message = correct_messages[randi() % correct_messages.size()]
		show_alert(message, true)
		
		if score >= total_matches:
			game_complete()
		return true
	else:
		# Wrong match
		show_feedback(drop_zone, false)
		
		# Show encouraging message
		var message = wrong_messages[randi() % wrong_messages.size()]
		show_alert(message, false)
		
		return false

func show_feedback(zone: Panel, is_correct: bool):
	"""Show visual feedback for match attempt"""
	var style_box = StyleBoxFlat.new()
	
	if is_correct:
		style_box.bg_color = Color(0.2, 0.8, 0.2, 0.9)
		style_box.border_color = Color.GREEN
	else:
		style_box.bg_color = Color(0.8, 0.2, 0.2, 0.7)
		style_box.border_color = Color.RED
	
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	zone.add_theme_stylebox_override("panel", style_box)
	
	if not is_correct:
		await get_tree().create_timer(1.0).timeout
		var original_style = StyleBoxFlat.new()
		original_style.bg_color = Color(0.2, 0.3, 0.5, 0.8)
		original_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
		original_style.border_width_left = 2
		original_style.border_width_top = 2
		original_style.border_width_right = 2
		original_style.border_width_bottom = 2
		original_style.corner_radius_top_left = 8
		original_style.corner_radius_top_right = 8
		original_style.corner_radius_bottom_left = 8
		original_style.corner_radius_bottom_right = 8
		zone.add_theme_stylebox_override("panel", original_style)

func game_complete():
	"""Called when all matches are found"""
	show_alert("🎉 AMAZING! You matched all planets! 🎉", true)
	print("🎉 Game Complete! Score: ", score, "/", total_matches)
	await get_tree().create_timer(3.0).timeout
	setup_game()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

func _on_settings_pressed():
	print("Settings button pressed")

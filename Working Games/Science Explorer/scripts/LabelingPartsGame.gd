# labeling_parts_game.gd
extends Control

# Plant parts and their positions (multiple positions for leaves and flowers)
const PLANT_PARTS = {
	"root": {"positions": [Vector2(735, 520)], "word": "root"},
	"stem": {"positions": [Vector2(735, 400), Vector2(735, 450), Vector2(735, 350)], "word": "stem"}, 
	"leaf": {"positions": [Vector2(650, 320), Vector2(620, 280), Vector2(680, 300), Vector2(790, 320), Vector2(820, 280), Vector2(760, 300)], "word": "leaf"},
	"flower": {"positions": [Vector2(800, 250), Vector2(820, 230), Vector2(780, 270), Vector2(850, 240)], "word": "flower"}
}

# UI Elements
@onready var plant_sprite = $PlantSprite
@onready var character_sprite = $CharacterSprite
@onready var instruction_label = $InstructionPanel/InstructionLabel
@onready var word_container = $WordContainer
@onready var progress_bar = $ProgressBar
@onready var progress_label = $ProgressBar/ProgressLabel
@onready var celebration_panel = $CelebrationPanel
@onready var audio_player = $AudioStreamPlayer
@onready var background_music = $BackgroundMusic
@onready var success_audio = $SuccessAudio
@onready var calm_zone_button = $CalmZoneButton

# Word bubble references
@onready var root_bubble = $WordContainer/RootBubble
@onready var stem_bubble = $WordContainer/StemBubble
@onready var leaf_bubble = $WordContainer/LeafBubble
@onready var flower_bubble = $WordContainer/FlowerBubble

# Game state
var completed_parts = []
var current_dragging_label = null
var correct_placements = 0
var total_parts = 4
var drag_offset = Vector2.ZERO

# Accessibility features
var text_to_speech_enabled = true
var audio_cues_enabled = true
var current_focus_element = null

func _ready():
	setup_game()
	setup_accessibility()
	setup_word_bubbles()
	connect_navigation_buttons()
	start_game()

func setup_game():
	# Set up calm, engaging background
	modulate = Color(0.95, 0.98, 0.95)  # Soft green tint
	
	# Initialize progress
	progress_bar.value = 0
	progress_bar.max_value = total_parts
	progress_label.text = "0/4"
	
	# Start background music
	if background_music:
		background_music.volume_db = -25
		background_music.play()

func setup_accessibility():
	# Configure for different disabilities
	instruction_label.add_theme_font_size_override("font_size", 20)
	instruction_label.text = "Drag each word to the correct part of the plant!"
	

func setup_word_bubbles():
	# Store original positions for returning bubbles
	var bubbles = [root_bubble, stem_bubble, leaf_bubble, flower_bubble]
	var words = ["root", "stem", "leaf", "flower"]
	
	for i in range(bubbles.size()):
		var bubble = bubbles[i]
		var word = words[i]
		
		# Store metadata
		bubble.set_meta("word", word)
		bubble.set_meta("original_position", bubble.position)
		bubble.set_meta("bubble_sprite", bubble.get_node("BubbleSprite"))
		bubble.set_meta("text_label", bubble.get_node("WordLabel"))
		
		# Get the input area and connect signals
		var input_area = bubble.get_node("InputArea")
		if input_area:
			# Connect to the input area's gui_input signal
			if not input_area.gui_input.is_connected(_on_bubble_input):
				input_area.gui_input.connect(_on_bubble_input.bind(word))
			
			# Connect hover signals
			if not input_area.mouse_entered.is_connected(_on_bubble_hover):
				input_area.mouse_entered.connect(_on_bubble_hover.bind(word))
			if not input_area.mouse_exited.is_connected(_on_bubble_unhover):
				input_area.mouse_exited.connect(_on_bubble_unhover.bind(word))
			
			print("Connected signals for: ", word)
		else:
			print("WARNING: InputArea not found for bubble: ", word)

func connect_navigation_buttons():
	# Connect the back and next buttons
	var back_button = $"nav-buttons/back-button"
	var next_button = $"nav-buttons/next-button"
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)

func start_game():
	# Game is ready to play
	print("Game started and ready to play!")

func get_bubble_by_word(word: String) -> Control:
	match word:
		"root":
			return root_bubble
		"stem":
			return stem_bubble
		"leaf":
			return leaf_bubble
		"flower":
			return flower_bubble
		_:
			return null

func _on_bubble_input(event: InputEvent, word: String):
	var bubble = get_bubble_by_word(word)
	if not bubble:
		return
	
	# Skip if this bubble is already completed
	if word in completed_parts:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_dragging_bubble(word, bubble, event.position)
			else:
				stop_dragging_bubble(word, bubble)
	elif event is InputEventMouseMotion and current_dragging_label == bubble:
		# Update bubble position during drag
		bubble.global_position = event.global_position - drag_offset

func _on_bubble_hover(word: String):
	var bubble = get_bubble_by_word(word)
	if not bubble:
		return
	
	# Skip if already completed
	if word in completed_parts:
		return
		
	# Audio cue and visual feedback
	if audio_cues_enabled:
		play_word_audio(word)
	
	# Gentle bounce animation for bubble
	var bubble_sprite = bubble.get_meta("bubble_sprite")
	if bubble_sprite:
		var tween = create_tween()
		tween.tween_property(bubble_sprite, "scale", Vector2(0.3, 0.3), 0.2)
	
	# Highlight text
	var text_label = bubble.get_meta("text_label")
	if text_label:
		text_label.add_theme_color_override("font_color", Color.DARK_BLUE)

func _on_bubble_unhover(word: String):
	var bubble = get_bubble_by_word(word)
	if not bubble:
		return
	
	# Skip if already completed
	if word in completed_parts:
		return
		
	var bubble_sprite = bubble.get_meta("bubble_sprite")
	if bubble_sprite:
		var tween = create_tween()
		tween.tween_property(bubble_sprite, "scale", Vector2(0.3, 0.3), 0.2)
	
	# Reset text color
	var text_label = bubble.get_meta("text_label")
	if text_label:
		text_label.add_theme_color_override("font_color", Color.BLACK)

func start_dragging_bubble(word: String, bubble: Control, mouse_pos: Vector2):
	current_dragging_label = bubble
	bubble.z_index = 10
	
	# Calculate drag offset to keep mouse position relative to bubble
	drag_offset = mouse_pos
	
	# Visual feedback - make bubble slightly larger and more vibrant
	var bubble_sprite = bubble.get_meta("bubble_sprite")
	if bubble_sprite:
		bubble_sprite.modulate = Color(1.2, 1.2, 1.2)
		#bubble_sprite.scale = bubble_sprite.scale * 1.15
	
	# Audio feedback
	if audio_cues_enabled:
		play_pickup_sound()

func stop_dragging_bubble(word: String, bubble: Control):
	if current_dragging_label != bubble:
		return
		
	current_dragging_label = null
	bubble.z_index = 0
	
	# Reset visual feedback
	var bubble_sprite = bubble.get_meta("bubble_sprite")
	if bubble_sprite:
		bubble_sprite.modulate = Color(1.0, 1.0, 1.0)
		#bubble_sprite.scale = bubble_sprite.scale / 1.15
	
	# Check if dropped in correct position
	check_bubble_placement(word, bubble)

func check_bubble_placement(word: String, bubble: Control):
	var possible_positions = PLANT_PARTS[word]["positions"]
	var bubble_center = bubble.global_position + Vector2(70, 35)  # Center of bubble
	
	var closest_distance = INF
	var best_position = possible_positions[0]
	
	# Check distance to all possible positions for this plant part
	for position in possible_positions:
		var distance = bubble_center.distance_to(position)
		if distance < closest_distance:
			closest_distance = distance
			best_position = position
	
	print("Checking placement for ", word)
	print("  Bubble center: ", bubble_center)
	print("  Closest target position: ", best_position)
	print("  Distance: ", closest_distance)
	
	# More generous hit detection for accessibility
	if closest_distance < 150:  # Increased hit area even more
		print("Correct placement for ", word)
		# Correct placement!
		create_clean_label(word, bubble, best_position)
		mark_bubble_as_complete(word, bubble)
	else:
		print("Incorrect placement for ", word, " - returning to start")
		# Return to original position with animation
		return_bubble_to_start(bubble)

func create_clean_label(word: String, bubble: Control, target_position: Vector2):
	# Hide the original bubble with smooth animation
	var tween = create_tween()
	tween.parallel().tween_property(bubble, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.parallel().tween_property(bubble, "scale", Vector2(0.5, 0.5), 0.5)
	
	# Create a clean, professional label at the target position
	var label_container = Control.new()
	label_container.position = target_position - Vector2(40, 15)
	label_container.size = Vector2(80, 30)
	
	# Create a subtle background
	var background = ColorRect.new()
	background.size = Vector2(80, 30)
	background.color = Color(1, 1, 1, 0.9)  # Semi-transparent white
	background.position = Vector2(0, 0)
	label_container.add_child(background)
	
	# Add rounded corners using StyleBox
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_color = Color(0.3, 0.6, 0.3, 0.8)  # Subtle green border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	background.add_theme_stylebox_override("stylebox", style)
	
	# Add the word text
	var text_label = Label.new()
	text_label.text = word
	text_label.size = Vector2(80, 30)
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.2))  # Dark green
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_container.add_child(text_label)
	
	add_child(label_container)
	
	# Animate the label appearing
	label_container.modulate = Color(1, 1, 1, 0)
	label_container.scale = Vector2(0.5, 0.5)
	
	var appear_tween = create_tween()
	appear_tween.parallel().tween_property(label_container, "modulate", Color(1, 1, 1, 1), 0.6)
	appear_tween.parallel().tween_property(label_container, "scale", Vector2(1, 1), 0.6)
	
	# Add a gentle pulse effect
	await appear_tween.finished
	var pulse_tween = create_tween()
	pulse_tween.set_loops(2)
	pulse_tween.tween_property(label_container, "scale", Vector2(1.1, 1.1), 0.3)
	pulse_tween.tween_property(label_container, "scale", Vector2(1, 1), 0.3)

func mark_bubble_as_complete(word: String, bubble: Control):
	if word in completed_parts:
		return
		
	completed_parts.append(word)
	correct_placements += 1
	
	# Update progress
	progress_bar.value = correct_placements
	progress_label.text = str(correct_placements) + "/4"
	
	# Make bubble non-interactive
	var input_area = bubble.get_node("InputArea")
	if input_area:
		input_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Celebrate the correct placement
	celebrate_correct_placement(word)

func return_bubble_to_start(bubble: Control):
	# Get original position from metadata
	var original_pos = bubble.get_meta("original_position")
	
	var tween = create_tween()
	tween.tween_property(bubble, "position", original_pos, 0.5)

func celebrate_correct_placement(word: String):
	# Play success sound
	if success_audio:
		success_audio.play()
	
	# Encouraging message
	show_encouragement(word)
	
	# Check if game complete
	if correct_placements >= total_parts:
		await get_tree().create_timer(1.0).timeout
		complete_game()

func show_encouragement(word: String):
	var messages = [
		"Great job finding the " + word + "!",
		"Perfect! You found the " + word + "!",
		"Excellent work with the " + word + "!",
		"Amazing! The " + word + " is correct!"
	]
	
	var message = messages[randi() % messages.size()]
	instruction_label.text = message
	
	# Text-to-speech
	if text_to_speech_enabled:
		speak_text(message)
	
	# Reset instruction after delay
	await get_tree().create_timer(2.0).timeout
	if correct_placements < total_parts:
		instruction_label.text = "Keep going! Drag the next word to its plant part!"

func complete_game():

	
	# Play celebration music
	if background_music:
		background_music.stop()
	
	# Final encouragement
	instruction_label.text = "🌟 Fantastic! You labeled all the plant parts! 🌟"
	
	if text_to_speech_enabled:
		speak_text("Fantastic! You labeled all the plant parts!")
	
	# Option to play again or continue
	await get_tree().create_timer(3.0).timeout


func restart_game():
	get_tree().reload_current_scene()

func next_activity():
	# Navigate to next educational activity
	get_tree().change_scene_to_file("res://scenes/Scene1_ScienceMainMenu.tscn")



# Audio helper functions
func play_word_audio(word: String):
	var audio_file = "res://Assets/Audio/" + word + ".wav"
	if audio_player and FileAccess.file_exists(audio_file):
		audio_player.stream = load(audio_file)
		audio_player.play()

func play_pickup_sound():
	# Play a gentle pickup sound
	pass

func speak_text(_text: String):
	# Integrate with text-to-speech if available
	# This would need platform-specific implementation
	pass
	
func _on_back_button_pressed():
	# Navigate back to the cutscene
	get_tree().change_scene_to_file("res://scenes/Scene3_LabelingPartsCutscene.tscn")

func _on_next_button_pressed():
	# Navigate to the next game
	get_tree().change_scene_to_file("res://scenes/Scene6_FindingWordsCutscene.tscn")

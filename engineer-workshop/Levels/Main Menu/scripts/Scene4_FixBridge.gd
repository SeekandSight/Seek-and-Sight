extends Node2D

# Game variables
var current_word = ""
var score = 0
var bridge_sequence = []
var word_planks = []
var bridge_slots = []
var placed_planks = {}
var current_slot_index = 0
var is_dragging = false
var dragged_plank = null
var original_positions = {}

# First grade sight words - same as Scene 2
var sight_words = [
	"a", "about", "after", "all", "an", "and", "are", "as", "at", "back", "be", "because",
	"the", "to", "said", "you", "it", "I", "have", "go", "not", "do", "can", "had", 
	"get", "with", "this", "will", "went", "came", "into", "from", "good", "too", 
	"when", "see", "him", "two"
]

# Audio file paths
var word_audio_files = {}
var feedback_audio_files = {}

func _ready():
	initialize_game()
	setup_audio_system()
	load_feedback_audio_files()
	setup_bridge_sequence()
	next_word()

func initialize_game():
	# Get word planks (now only 3)
	word_planks = [
		$WordPlanksArea/WordPlank1,
		$WordPlanksArea/WordPlank2,
		$WordPlanksArea/WordPlank3
	]
	
	# Get bridge slots
	bridge_slots = [
		$BridgeArea/BridgeSlots/BridgeSlot1,
		$BridgeArea/BridgeSlots/BridgeSlot2,
		$BridgeArea/BridgeSlots/BridgeSlot3
	]
	
	# Store original positions
	for plank in word_planks:
		original_positions[plank] = plank.global_position
		setup_plank_interaction(plank)
	
	# Setup bridge slots
	for i in range(bridge_slots.size()):
		var slot = bridge_slots[i]
		setup_bridge_slot(slot, i)

func setup_bridge_sequence():
	# Generate a sequence of 3 words for the bridge
	var shuffled_words = sight_words.duplicate()
	shuffled_words.shuffle()
	bridge_sequence = shuffled_words.slice(0, 3)
	
	# Now we shuffle the bridge sequence to randomize plank order
	var plank_words = bridge_sequence.duplicate()
	plank_words.shuffle()
	
	# Assign words to planks (1:1 mapping - every plank will be used)
	for i in range(word_planks.size()):
		var word = plank_words[i]
		var plank = word_planks[i]
		var label = plank.get_node("PlankLabel" + str(i + 1))
		if label:
			label.text = word
		plank.set_meta("word", word)

func setup_plank_interaction(plank):
	plank.input_pickable = true
	plank.monitoring = true
	plank.monitorable = true
	
	var input_callable = func(viewport, event, shape_idx): 
		_handle_plank_input(plank, viewport, event, shape_idx)
	var hover_callable = func():
		_handle_plank_hover(plank)
	var unhover_callable = func():
		_handle_plank_unhover(plank)
	
	plank.input_event.connect(input_callable)
	plank.mouse_entered.connect(hover_callable)
	plank.mouse_exited.connect(unhover_callable)

func setup_bridge_slot(slot, index):
	slot.input_pickable = true
	slot.monitoring = true
	slot.monitorable = true
	
	var area_enter_callable = func(area):
		_on_bridge_slot_area_entered(slot, area)
	var area_exit_callable = func(area):
		_on_bridge_slot_area_exited(slot, area)
	
	slot.area_entered.connect(area_enter_callable)
	slot.area_exited.connect(area_exit_callable)

func setup_audio_system():
	$UI/AudioPanel/PlayButton.pressed.connect(_on_play_button_pressed)
	$UI/NavButtons/BackButton.pressed.connect(_on_back_button_pressed)
	$UI/NavButtons/NextButton.pressed.connect(_on_next_button_pressed)
	load_word_audio_files()
	load_feedback_audio_files()

func load_feedback_audio_files():
	var feedback_sounds = {
		"awesome": "res://Assets/Audio/Feedback/AWESOME.wav",
		"great_job": "res://Assets/Audio/Feedback/GREAT JOB.wav",
		"one_more_time": "res://Assets/Audio/Feedback/ONE MORE TIME.wav",
		"not_quiet": "res://Assets/Audio/Feedback/NOT QUIET.wav",
		"way_to_go": "res://Assets/Audio/Feedback/WAY TO GO.wav",
		"instructions": "res://Assets/Audio/Engineer Workshop (Temp)/DRAG THE WORDS TO MATCH THE TOOLS.wav"
	}
	
	for key in feedback_sounds:
		var audio_path = feedback_sounds[key]
		if ResourceLoader.exists(audio_path):
			feedback_audio_files[key] = load(audio_path)
		else:
			feedback_audio_files[key] = null

func load_word_audio_files():
	for word in sight_words:
		var audio_paths = [
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word.to_upper() + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word.capitalize() + ".wav",
			"res://Assets/Audio/Grade Level/" + word.to_upper() + ".wav",
			"res://Assets/Audio/Grade Level/" + word + ".wav",
			"res://Assets/Audio/Grade Level/" + word.capitalize() + ".wav"
		]
		
		var audio_loaded = false
		for audio_path in audio_paths:
			if ResourceLoader.exists(audio_path):
				word_audio_files[word] = load(audio_path)
				audio_loaded = true
				break
		
		if not audio_loaded:
			word_audio_files[word] = null

func next_word():
	if current_slot_index >= bridge_sequence.size():
		complete_bridge()
		return
	
	current_word = bridge_sequence[current_slot_index]
	$UI/AudioPanel/CurrentWordLabel.text = current_word
	update_instruction_text("Find and drag: \"" + current_word + "\" to fix the bridge!")
	play_word_audio(current_word)
	
	# Highlight current slot
	highlight_current_slot()

func highlight_current_slot():
	# Reset all slot highlights
	for i in range(bridge_slots.size()):
		var slot = bridge_slots[i]
		var panel = slot.get_node("SlotPanel" + str(i + 1))
		if panel:
			if i == current_slot_index:
				panel.modulate = Color(1.2, 1.2, 0.8, 1)  # Highlight current slot
			else:
				panel.modulate = Color.WHITE

func play_word_audio(word):
	await get_tree().create_timer(3.0).timeout
	if word in word_audio_files and word_audio_files[word] != null:
		$Audio/WordAudio.stream = word_audio_files[word]
		$Audio/WordAudio.play()
	else:
		use_text_to_speech(word)

func play_feedback_audio(feedback_type):
	var audio_key = ""
	
	match feedback_type:
		"correct":
			var correct_sounds = ["awesome", "great_job", "way_to_go"]
			audio_key = correct_sounds[randi() % correct_sounds.size()]
		"wrong":
			var wrong_sounds = ["one_more_time", "not_quiet"]
			audio_key = wrong_sounds[randi() % wrong_sounds.size()]
		"encouragement":
			audio_key = "way_to_go"
	
	if audio_key in feedback_audio_files and feedback_audio_files[audio_key] != null:
		$Audio/CorrectSound.stream = feedback_audio_files[audio_key]
		$Audio/CorrectSound.play()
		print("Playing feedback audio: " + feedback_type)

func use_text_to_speech(word):
	# TODO: Implement TTS fallback
	pass

func _on_play_button_pressed():
	play_word_audio(current_word)

func _handle_plank_input(plank, viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_plank_used(plank):
				return
			start_dragging(plank)

func _handle_plank_hover(plank):
	if not is_dragging and not is_plank_used(plank):
		plank.scale = Vector2(1.1, 1.1)

func _handle_plank_unhover(plank):
	if not is_dragging and not is_plank_used(plank):
		plank.scale = Vector2(1.0, 1.0)

func start_dragging(plank):
	is_dragging = true
	dragged_plank = plank
	
	if not original_positions.has(plank):
		original_positions[plank] = plank.global_position
	
	plank.modulate = Color.YELLOW
	plank.z_index = 1000
	plank.scale = Vector2(1.2, 1.2)
	update_instruction_text("Drag the plank to the highlighted bridge slot!")

func stop_dragging():
	if not dragged_plank:
		return
	
	var dropped_in_slot = false
	
	# Check if dropped in any bridge slot
	for i in range(bridge_slots.size()):
		var slot = bridge_slots[i]
		var slot_rect = get_slot_rect(slot)
		var mouse_pos = get_global_mouse_position()
		
		if slot_rect.has_point(mouse_pos):
			drop_plank_in_slot(dragged_plank, slot, i)
			dropped_in_slot = true
			break
	
	if not dropped_in_slot:
		return_to_start(dragged_plank)
	
	# Reset plank appearance
	dragged_plank.modulate = Color.WHITE
	dragged_plank.z_index = 0
	dragged_plank.scale = Vector2(1.0, 1.0)
	
	is_dragging = false
	dragged_plank = null

func get_slot_rect(slot):
	var slot_pos = slot.global_position
	var slot_size = Vector2(130, 50)  # Same as collision shape
	return Rect2(slot_pos - slot_size/2, slot_size)

func drop_plank_in_slot(plank, slot, slot_index):
	var plank_word = plank.get_meta("word")
	
	# Check if this is the correct slot for current word
	if slot_index == current_slot_index and plank_word == current_word:
		correct_placement(plank, slot, slot_index)
	else:
		wrong_placement(plank, slot, slot_index)

func correct_placement(plank, slot, slot_index):
	# Place plank in slot
	place_plank_in_slot(plank, slot, slot_index)
	
	# Update game state
	score += 15
	$UI/AudioPanel/ScoreLabel.text = "Score: " + str(score)
	placed_planks[slot_index] = plank
	current_slot_index += 1
	
	# Play correct sound and feedback
	play_feedback_audio("correct")
	show_feedback("Perfect! Great building!", false)
	
	# Hide the slot's "MISSING" label
	var slot_label = slot.get_node("SlotLabel" + str(slot_index + 1))
	if slot_label:
		slot_label.visible = false
	
	# Wait before next word
	await get_tree().create_timer(1.5).timeout
	next_word()

func wrong_placement(plank, slot, slot_index):
	# Check if slot is already occupied
	if slot_index in placed_planks:
		show_feedback("This spot is already filled! Try another spot.", true)
		return_to_start(plank)
		return
	
	# Check if it's the wrong word for current slot
	if slot_index == current_slot_index:
		show_feedback("Not quite right! Listen again and try a different plank.", true)
	else:
		show_feedback("Place the planks in order from left to right!", true)
	
	play_feedback_audio("wrong")
	return_to_start(plank)
	
	# Replay current word after a moment
	await get_tree().create_timer(1.0).timeout
	play_word_audio(current_word)

func place_plank_in_slot(plank, slot, slot_index):
	# Move plank to slot position
	var slot_pos = slot.global_position
	plank.global_position = slot_pos
	
	# Create placed plank visual
	var placed_plank = create_bridge_plank(plank.get_meta("word"))
	placed_plank.position = Vector2(0, 0)
	slot.add_child(placed_plank)
	
	# Hide original plank
	hide_plank(plank)
	
	# Animation for placing
	placed_plank.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(placed_plank, "scale", Vector2(0.5, 0.5), 0.5)

func create_bridge_plank(word):
	var plank_sprite = Sprite2D.new()
	
	# Try to load the texture, with fallback to a colored rectangle if not found
	var texture_path = "res://Assets/Engineers Workshop/EllieBlocks1.png"
	if ResourceLoader.exists(texture_path):
		plank_sprite.texture = load(texture_path)
		plank_sprite.scale = Vector2(0.4, 0.3)
	else:
		# Fallback: create a colored rectangle if texture not found
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(120, 30)
		color_rect.color = Color(0.6, 0.4, 0.2, 1)  # Brown color for wood plank
		color_rect.position = Vector2(-60, -15)
		plank_sprite.add_child(color_rect)
	
	var label = Label.new()
	label.text = word
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -15)
	label.size = Vector2(120, 30)
	label.add_theme_color_override("font_color", Color(0.243137, 0.145098, 0.062745, 1))
	
	var font_path = "res://Assets/Fonts/Chewy-Regular.ttf"
	if ResourceLoader.exists(font_path):
		label.add_theme_font_override("font", load(font_path))
	label.add_theme_font_size_override("font_size", 26)
	
	plank_sprite.add_child(label)
	return plank_sprite

func hide_plank(plank):
	var tween = create_tween()
	tween.parallel().tween_property(plank, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(plank, "scale", Vector2(0.5, 0.5), 0.5)

func return_to_start(plank):
	var original_pos = original_positions[plank]
	var tween = create_tween()
	tween.tween_property(plank, "global_position", original_pos, 0.5)

func show_feedback(message, is_error):
	update_instruction_text(message)

func update_instruction_text(text):
	$UI/InstructionBubble/InstructionText.text = text

func is_plank_used(plank):
	var plank_word = plank.get_meta("word")
	for placed_plank in placed_planks.values():
		if placed_plank.get_meta("word") == plank_word:
			return true
	return false

func complete_bridge():
	show_feedback("AMAZING! You fixed the bridge!", false)
	update_instruction_text("🎉 Perfect! All planks placed! 🎉\nNow watch Ellie cross!")
	
	# Play bridge complete sound
	play_feedback_audio("correct")
	
	# Wait a moment before starting crossing animation
	await get_tree().create_timer(1.0).timeout
	
	# Animate Ellie crossing the bridge
	animate_ellie_crossing()
	
	# Enable next button (will be enabled after crossing animation)
	await get_tree().create_timer(6.0).timeout  # Wait for crossing animation to complete
	$UI/NavButtons/NextButton.disabled = false
	$UI/NavButtons/NextButton.text = "Amazing! Next →"

func animate_ellie_crossing():
	var ellie = $Background/EllieInstructor
	var start_pos = ellie.position
	var bridge_start = Vector2(350, 310)  # Better aligned with bridge level
	var bridge_end = Vector2(870, 400)    # Right side past the bridge
	
	# Show starting message
	update_instruction_text("Watch Ellie cross the safe bridge!")
	
	# First move Ellie to the bridge start
	var tween1 = create_tween()
	tween1.tween_property(ellie, "position", bridge_start, 1.0)
	await tween1.finished
	
	# Then cross the bridge
	var tween2 = create_tween()
	tween2.tween_property(ellie, "position", bridge_end, 2.5)
	
	# Show crossing message
	update_instruction_text("Ellie is crossing the bridge you built!")
	
	# Make Ellie wave after crossing
	await tween2.finished
	
	# Celebration messages
	update_instruction_text("🎉 HURRAY! Ellie crossed the bridge safely! 🎉")
	play_feedback_audio("encouragement")
	
	await get_tree().create_timer(1.0).timeout
	
	# Bounce animation to show celebration
	var bounce_tween = create_tween()
	bounce_tween.tween_property(ellie, "position:y", bridge_end.y - 30, 0.4)
	bounce_tween.tween_property(ellie, "position:y", bridge_end.y, 0.4)
	
	await bounce_tween.finished
	await get_tree().create_timer(0.5).timeout
	
	# Final celebration message
	update_instruction_text("🌟 AMAZING WORK! You're a bridge-building expert! 🌟\nReady for the next adventure?")

func _on_bridge_slot_area_entered(slot, area):
	if is_dragging and area == dragged_plank:
		# Visual feedback when hovering over slot
		var slot_panel = slot.get_child(1)  # Assuming SlotPanel is second child
		if slot_panel:
			slot_panel.modulate = Color(0.8, 1.0, 0.8, 1.0)

func _on_bridge_slot_area_exited(slot, area):
	if is_dragging and area == dragged_plank:
		# Reset visual feedback
		var slot_panel = slot.get_child(1)
		if slot_panel:
			slot_panel.modulate = Color.WHITE

func _process(delta):
	if is_dragging and dragged_plank:
		dragged_plank.global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				stop_dragging()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene1_Welcome.tscn")

func _on_next_button_pressed():
	get_tree().quit()

func reset_game():
	score = 0
	current_slot_index = 0
	placed_planks.clear()
	current_word = ""
	
	# Clear placed planks from bridge
	for slot in bridge_slots:
		for child in slot.get_children():
			if child.has_method("get_script") and child.get_script() == null:
				# Remove dynamically created plank sprites
				if child is Sprite2D and child.get_parent() == slot:
					child.queue_free()
		
		# Show slot labels again
		var slot_index = bridge_slots.find(slot)
		var slot_label = slot.get_node("SlotLabel" + str(slot_index + 1))
		if slot_label:
			slot_label.visible = true
			slot_label.text = "MISSING"
	
	# Reset word planks
	for plank in word_planks:
		plank.modulate = Color.WHITE
		plank.scale = Vector2(1.0, 1.0)
		plank.global_position = original_positions[plank]
	
	# Reset Ellie position
	$Background/EllieInstructor.position = Vector2(50, 475)
	
	# Reset UI
	$UI/AudioPanel/ScoreLabel.text = "Score: 0"
	$UI/AudioPanel/CurrentWordLabel.text = "Click Play!"
	$UI/NavButtons/NextButton.disabled = true
	$UI/NavButtons/NextButton.text = "Next →"
	
	# Generate new bridge sequence
	setup_bridge_sequence()
	next_word()

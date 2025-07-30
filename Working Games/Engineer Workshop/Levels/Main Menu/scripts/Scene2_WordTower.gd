extends Node2D

# Game variables
var current_word = ""
var score = 0
var tower_blocks = []
var word_blocks = []
var used_words = []
var words_in_round = []
var total_words = 5
var is_dragging = false
var dragged_block = null
var original_positions = {}

# First grade sight words - matching your audio files
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
	load_all_audio_files()
	next_word()

func initialize_game():
	word_blocks = [
		$WordBlocksArea/WordBlock1,
		$WordBlocksArea/WordBlock2,
		$WordBlocksArea/WordBlock3,
		$WordBlocksArea/WordBlock4,
		$WordBlocksArea/WordBlock5
	]
	
	for block in word_blocks:
		original_positions[block] = block.global_position
	
	generate_round_words()
	
	$TowerArea/TowerDropZone.body_entered.connect(_on_tower_drop_zone_entered)
	$TowerArea/TowerDropZone.body_exited.connect(_on_tower_drop_zone_exited)

func generate_round_words():
	var shuffled_words = sight_words.duplicate()
	shuffled_words.shuffle()
	words_in_round = shuffled_words.slice(0, total_words)
	
	print("Selected words for this round: ", words_in_round)
	
	# Don't override the positions - use the positions set in the .tscn file
	# The word blocks are already positioned in your scene file at specific locations
	
	for i in range(word_blocks.size()):
		if i < words_in_round.size():
			var word = words_in_round[i]
			var block = word_blocks[i]
			
			var label = block.get_node("WordBlockLabel" + str(i + 1))
			if label:
				label.text = word
				print("✅ Set word '" + word + "' on block " + str(i + 1))
			else:
				print("❌ Could not find label for block " + str(i + 1))
			
			block.set_meta("word", word)
			# DON'T change position - keep the .tscn positions
			# block.position = Vector2(0, start_y + i * spacing)  # REMOVED THIS LINE
			block.visible = true  # Make sure block is visible
			setup_word_block_interaction(block)
		else:
			# Hide unused blocks
			word_blocks[i].visible = false

func setup_word_block_interaction(block):
	block.input_pickable = true
	block.monitoring = true
	block.monitorable = true
	
	var input_callable = func(viewport, event, shape_idx): 
		_handle_block_input(block, viewport, event, shape_idx)
	var hover_callable = func():
		_handle_block_hover(block)
	var unhover_callable = func():
		_handle_block_unhover(block)
	
	block.input_event.connect(input_callable)
	block.mouse_entered.connect(hover_callable)
	block.mouse_exited.connect(unhover_callable)

func setup_audio_system():
	# Connect play button
	$UI/AudioPanel/PlayButton.pressed.connect(_on_play_button_pressed)
	
	# Connect navigation buttons
	$UI/NavButtons/BackButton.pressed.connect(_on_back_button_pressed)
	$UI/NavButtons/NextButton.pressed.connect(_on_next_button_pressed)

func load_all_audio_files():
	print("=== LOADING AUDIO FILES ===")
	load_word_audio_files()
	load_feedback_audio_files()
	print("=== AUDIO LOADING COMPLETE ===")

func load_word_audio_files():
	# Based on your ACTUAL folder structure
	for word in sight_words:
		var audio_loaded = false
		
		# Try different paths based on your structure
		var audio_paths = [
			# First Grade Words folder (highest priority)
			"res://Assets/Audio/Grade Level/" + word.to_upper() + ".wav",
			"res://Assets/Audio/Grade Level/" + word.capitalize() + ".wav",
			"res://Assets/Audio/Grade Level/" + word + ".wav",
			
			# Engineer Workshop (Temp) folder
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word.to_upper() + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word.capitalize() + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + word + ".wav",
			
			# Feedback folder
			"res://Assets/Audio/Feedback/" + word.to_upper() + ".wav",
			"res://Assets/Audio/Feedback/" + word.capitalize() + ".wav",
			"res://Assets/Audio/Feedback/" + word + ".wav",
			
			# Direct Engineers Workshop folder
			"res://Assets/Engineers Workshop/" + word.to_upper() + ".wav",
			"res://Assets/Engineers Workshop/" + word.capitalize() + ".wav",
			"res://Assets/Engineers Workshop/" + word + ".wav",
			
			# Root Assets folder
			"res://Assets/" + word.to_upper() + ".wav",
			"res://Assets/" + word.capitalize() + ".wav",
			"res://Assets/" + word + ".wav"
		]
		
		for audio_path in audio_paths:
			if ResourceLoader.exists(audio_path):
				var audio_stream = load(audio_path)
				if audio_stream:
					word_audio_files[word] = audio_stream
					print("✅ Loaded audio for '" + word + "' from: " + audio_path)
					audio_loaded = true
					break
		
		if not audio_loaded:
			print("❌ Audio file not found for: " + word)
			word_audio_files[word] = null

func load_feedback_audio_files():
	# Load feedback sounds from your actual folder structure
	var feedback_sounds = {
		"correct": [
			"res://Assets/Audio/Feedback/AWESOME.wav",
			"res://Assets/Audio/Feedback/GREAT JOB.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/AWESOME.wav",
			"res://Assets/Engineers Workshop/AWESOME.wav",
			"res://Assets/AWESOME.wav"
		],
		"wrong": [
			"res://Assets/Audio/Feedback/ONE MORE TIME.wav",
			"res://Assets/Audio/Feedback/NOT QUIET.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/ONE MORE TIME.wav",
			"res://Assets/Engineers Workshop/ONE MORE TIME.wav",
			"res://Assets/ONE MORE TIME.wav"
		],
		"encouragement": [
			"res://Assets/Audio/Feedback/WAY TO GO.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/WAY TO GO.wav",
			"res://Assets/Engineers Workshop/WAY TO GO.wav",
			"res://Assets/WAY TO GO.wav"
		],
		"welcome": [
			"res://Assets/Audio/Engineer Workshop (Temp)/HI! I'M ELLIE! WELCOME TO MY CONSTRUCTION SITE! LET'S BUILD A TOWER TOGETHER!.wav",
			"res://Assets/Engineers Workshop/HI! I'M ELLIE! WELCOME TO MY CONSTRUCTION SITE! LET'S BUILD A TOWER TOGETHER!.wav"
		],
		"instruction": [
			"res://Assets/Audio/Engineer Workshop (Temp)/LISTEN TO THE WORD AND DRAG IT TO BUILD YOUR TOWER!.wav",
			"res://Assets/Engineers Workshop/LISTEN TO THE WORD AND DRAG IT TO BUILD YOUR TOWER!.wav"
		],
		"tools": [
			"res://Assets/Audio/Engineer Workshop (Temp)/DRAG THE WORDS TO MATCH THE TOOLS.wav",
			"res://Assets/Engineers Workshop/DRAG THE WORDS TO MATCH THE TOOLS.wav"
		]
	}
	
	for category in feedback_sounds:
		feedback_audio_files[category] = []
		for audio_path in feedback_sounds[category]:
			if ResourceLoader.exists(audio_path):
				var audio_stream = load(audio_path)
				if audio_stream:
					feedback_audio_files[category].append(audio_stream)
					print("✅ Loaded feedback audio: " + audio_path)

func next_word():
	if used_words.size() >= words_in_round.size():
		complete_game()
		return
	
	var available_words = words_in_round.filter(func(word): return word not in used_words)
	current_word = available_words[randi() % available_words.size()]
	
	$UI/AudioPanel/CurrentWordLabel.text = current_word
	update_instruction_text("Find and drag: \"" + current_word + "\"")
	play_word_audio(current_word)

func play_word_audio(word):
	await get_tree().create_timer(3.0).timeout
	print("Attempting to play audio for word: ", word)
	
	# Stop any currently playing audio
	$Audio/WordAudio.stop()
	
	if word in word_audio_files and word_audio_files[word] != null:
		$Audio/WordAudio.stream = word_audio_files[word]
		$Audio/WordAudio.play()
		print("✅ Playing audio file for: " + word)
		show_word_visually(word)
	else:
		print("❌ No audio file found for: " + word)
		show_word_visually(word)

func show_word_visually(word):
	# Show the word with visual emphasis
	var current_label = $UI/AudioPanel/CurrentWordLabel
	current_label.text = "🔊 " + word.to_upper()
	
	# Flash the word
	var original_color = current_label.modulate
	current_label.modulate = Color.YELLOW
	
	var tween = create_tween()
	tween.tween_property(current_label, "modulate", original_color, 1.0)

func play_feedback_audio(category):
	if category in feedback_audio_files and feedback_audio_files[category].size() > 0:
		var audio_streams = feedback_audio_files[category]
		var random_audio = audio_streams[randi() % audio_streams.size()]
		$Audio/CorrectSound.stream = random_audio
		$Audio/CorrectSound.play()
		print("Playing feedback audio: ", category)

func _on_play_button_pressed():
	play_word_audio(current_word)

func _handle_block_input(block, viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_word_used(block):
				return
			start_dragging(block)

func _handle_block_hover(block):
	if not is_dragging:
		block.scale = Vector2(1.1, 1.1)

func _handle_block_unhover(block):
	if not is_dragging:
		block.scale = Vector2(1.0, 1.0)

func start_dragging(block):
	is_dragging = true
	dragged_block = block
	
	if not original_positions.has(block):
		original_positions[block] = block.global_position
	
	block.modulate = Color.YELLOW
	block.z_index = 1000
	block.scale = Vector2(1.3, 1.3)
	update_instruction_text("Drag to the tower area!")

func stop_dragging():
	if not dragged_block:
		return
	
	var mouse_pos = get_global_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size
	var tower_center = Vector2(screen_size.x * 0.75, screen_size.y * 0.5)
	var tower_bounds = Rect2(tower_center - Vector2(200, 300), Vector2(400, 600))
	
	if tower_bounds.has_point(mouse_pos):
		check_word_match(dragged_block)
	else:
		return_to_start(dragged_block)
	
	dragged_block.modulate = Color.WHITE
	dragged_block.z_index = 0
	dragged_block.scale = Vector2(1.0, 1.0)
	
	is_dragging = false
	dragged_block = null

func check_word_match(block):
	var block_word = block.get_meta("word")
	
	if block_word == current_word:
		correct_match(block, block_word)
	else:
		wrong_match(block)

func correct_match(block, word):
	add_block_to_tower(word)
	score += 10
	$UI/AudioPanel/ScoreLabel.text = "Score: " + str(score)
	used_words.append(word)
	hide_word_block(block)
	
	# Play correct feedback audio
	play_feedback_audio("correct")
	
	show_feedback("Perfect! Great building!", false)
	await get_tree().create_timer(1.5).timeout
	next_word()

func wrong_match(block):
	# Play wrong feedback audio
	play_feedback_audio("wrong")
	
	show_feedback("Try again! Listen carefully!", true)
	return_to_start(block)
	await get_tree().create_timer(1.0).timeout
	play_word_audio(current_word)

func add_block_to_tower(word):
	var tower_block = create_tower_block(word)
	var tower_container = $TowerArea/TowerBlocks
	
	# Calculate position to stack blocks properly on top of each other
	var final_block_scale = 0.5
	var estimated_block_height = 60
	var gap_between_blocks = 5
	
	# Stack upward (negative Y) with proper spacing based on actual block height
	var y_offset = -(estimated_block_height + gap_between_blocks) * tower_blocks.size()
	tower_block.position = Vector2(0, y_offset)
	
	print("Block ", tower_blocks.size() + 1, " positioned at: ", tower_block.position)
	
	tower_container.add_child(tower_block)
	tower_blocks.append(tower_block)
	
	tower_block.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(tower_block, "scale", Vector2(0.5, 0.5), 0.5)

func create_tower_block(word):
	var block_sprite = Sprite2D.new()
	
	# Try multiple paths for the block texture based on your structure
	var texture_paths = [
		"res://Assets/EllieBlocks1.png",  # Root Assets (as shown in your .tscn)
		"res://Assets/Engineers Workshop/EllieBlocks1.png",
		"res://Assets/Engineers Workshop/EllieBlocks.png"
	]
	
	for texture_path in texture_paths:
		if ResourceLoader.exists(texture_path):
			block_sprite.texture = load(texture_path)
			print("✅ Loaded block texture from: " + texture_path)
			break
	
	var label = Label.new()
	label.text = word
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -15)
	label.size = Vector2(120, 30)
	label.add_theme_color_override("font_color", Color(0.243137, 0.145098, 0.062745, 1))
	
	# Try multiple font paths based on your structure
	var font_paths = [
		"res://Assets/Chewy-Regular.ttf",  # Root Assets (as shown in your .tscn)
		"res://Assets/Fonts/Chewy-Regular.ttf"
	]
	
	for font_path in font_paths:
		if ResourceLoader.exists(font_path):
			label.add_theme_font_override("font", load(font_path))
			print("✅ Loaded font from: " + font_path)
			break
	
	label.add_theme_font_size_override("font_size", 40)
	
	block_sprite.add_child(label)
	
	return block_sprite

func hide_word_block(block):
	var tween = create_tween()
	tween.parallel().tween_property(block, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(block, "scale", Vector2(0.5, 0.5), 0.5)

func return_to_start(block):
	var original_pos = original_positions[block]
	var tween = create_tween()
	tween.tween_property(block, "global_position", original_pos, 0.5)

func show_feedback(message, is_error):
	update_instruction_text(message)

func update_instruction_text(text):
	$UI/InstructionBubble/InstructionText.text = text

func is_word_used(block):
	var word = block.get_meta("word")
	return word in used_words

func complete_game():
	show_feedback("AMAZING WORK! Tower Complete!", false)
	update_instruction_text("Outstanding! You built an amazing tower! Ready for the next challenge?")
	
	# Play celebration audio
	play_feedback_audio("encouragement")
	
	$UI/NavButtons/NextButton.disabled = false
	$UI/NavButtons/NextButton.text = "Amazing! Next →"

func _process(delta):
	if is_dragging and dragged_block:
		dragged_block.global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				stop_dragging()

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("setup_responsive_layout")

func _on_tower_drop_zone_entered(body):
	$TowerArea/TowerDropZone.modulate = Color(0.5, 1.0, 0.5, 0.5)

func _on_tower_drop_zone_exited(body):
	$TowerArea/TowerDropZone.modulate = Color.WHITE

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene1_Welcome.tscn")

func _on_next_button_pressed():
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene3_ToolMatch.tscn")

func reset_game():
	score = 0
	tower_blocks.clear()
	used_words.clear()
	current_word = ""
	
	for child in $TowerArea/TowerBlocks.get_children():
		child.queue_free()
	
	for block in word_blocks:
		block.modulate = Color.WHITE
		block.scale = Vector2(1.0, 1.0)
		block.global_position = original_positions[block]
	
	$UI/AudioPanel/ScoreLabel.text = "Score: 0"
	$UI/AudioPanel/CurrentWordLabel.text = "Click Play!"
	$UI/NavButtons/NextButton.disabled = true
	$UI/NavButtons/NextButton.text = "Next →"
	
	generate_round_words()
	next_word()

# Debug function to test audio files
func test_all_audio():
	print("=== TESTING ALL AUDIO FILES ===")
	for word in word_audio_files:
		if word_audio_files[word] != null:
			print("✅ Audio available for: ", word)
		else:
			print("❌ No audio for: ", word)
	
	for category in feedback_audio_files:
		print("Feedback category '", category, "' has ", feedback_audio_files[category].size(), " files")
		

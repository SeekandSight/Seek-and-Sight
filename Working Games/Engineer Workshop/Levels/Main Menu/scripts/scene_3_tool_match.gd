# Scene3_ToolMatch.gd - Updated with Correct Asset Paths
# Attach this script to the Scene3_ToolMatch root node

extends Node2D

var is_dragging = false
var dragged_tool = null
var original_tool_positions = {}
var matches_made = 0
var total_matches = 4
var matched_pairs = {}

# Audio system variables
var word_audio_files = {}
var feedback_audio_files = {}

func _ready():
	store_original_positions()
	setup_tools()
	load_all_audio_files()
	play_welcome_audio()

func store_original_positions():
	var tools = [
		$ToolArea/HammerSlot,
		$ToolArea/WrenchSlot,
		$ToolArea/ScrewdriverSlot,
		$ToolArea/SawSlot
	]
	
	for tool in tools:
		if tool:
			original_tool_positions[tool] = tool.global_position

func setup_tools():
	var tools = [
		$ToolArea/HammerSlot,
		$ToolArea/WrenchSlot,
		$ToolArea/ScrewdriverSlot,
		$ToolArea/SawSlot
	]
	
	for tool in tools:
		if tool:
			tool.input_event.connect(_on_tool_input_event)
			tool.mouse_entered.connect(_on_tool_hover.bind(tool))
			tool.mouse_exited.connect(_on_tool_unhover.bind(tool))

func load_all_audio_files():
	print("=== LOADING TOOL MATCH AUDIO FILES ===")
	load_tool_audio_files()
	load_feedback_audio_files()
	print("=== AUDIO LOADING COMPLETE ===")

func load_tool_audio_files():
	# Tool names based on your audio files
	var tool_names = ["hammer", "wrench", "screwdriver", "saw"]
	
	for tool_name in tool_names:
		var audio_loaded = false
		
		# Try different paths based on your folder structure
		var audio_paths = [
			# Engineer Workshop (Temp) folder - where your tool audio files are
			"res://Assets/Audio/Engineer Workshop (Temp)/" + tool_name.to_upper() + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + tool_name.capitalize() + ".wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/" + tool_name + ".wav",
			
			# First Grade Words folder
			"res://Assets/Audio/Grade Level/" + tool_name.to_upper() + ".wav",
			"res://Assets/Audio/Grade Level/" + tool_name.capitalize() + ".wav",
			"res://Assets/Audio/Grade Level/" + tool_name + ".wav",
			
			# Feedback folder
			"res://Assets/Audio/Feedback/" + tool_name.to_upper() + ".wav",
			"res://Assets/Audio/Feedback/" + tool_name.capitalize() + ".wav",
			"res://Assets/Audio/Feedback/" + tool_name + ".wav",
			
			# Engineers Workshop folder
			"res://Assets/Engineers Workshop/" + tool_name.to_upper() + ".wav",
			"res://Assets/Engineers Workshop/" + tool_name.capitalize() + ".wav",
			"res://Assets/Engineers Workshop/" + tool_name + ".wav"
		]
		
		for audio_path in audio_paths:
			if ResourceLoader.exists(audio_path):
				var audio_stream = load(audio_path)
				if audio_stream:
					word_audio_files[tool_name] = audio_stream
					print("✅ Loaded tool audio for '" + tool_name + "' from: " + audio_path)
					audio_loaded = true
					break
		
		if not audio_loaded:
			print("❌ Tool audio file not found for: " + tool_name)
			word_audio_files[tool_name] = null

func load_feedback_audio_files():
	# Load feedback sounds from your folder structure
	var feedback_sounds = {
		"correct": [
			"res://Assets/Audio/Feedback/AWESOME.wav",
			"res://Assets/Audio/Feedback/GREAT JOB.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/AWESOME.wav",
			"res://Assets/Engineers Workshop/AWESOME.wav"
		],
		"wrong": [
			"res://Assets/Audio/Feedback/ONE MORE TIME.wav",
			"res://Assets/Audio/Feedback/NOT QUIET.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/ONE MORE TIME.wav",
			"res://Assets/Engineers Workshop/ONE MORE TIME.wav"
		],
		"encouragement": [
			"res://Assets/Audio/Feedback/WAY TO GO.wav",
			"res://Assets/Audio/Engineer Workshop (Temp)/WAY TO GO.wav",
			"res://Assets/Engineers Workshop/WAY TO GO.wav"
		],
		"welcome": [
			"res://Assets/Audio/Engineer Workshop (Temp)/HI! I'M ELLIE! WELCOME TO MY CONSTRUCTION SITE! LET'S BUILD A TOWER TOGETHER!.wav",
			"res://Assets/Engineers Workshop/HI! I'M ELLIE! WELCOME TO MY CONSTRUCTION SITE! LET'S BUILD A TOWER TOGETHER!.wav"
		],
		"tools_instruction": [
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

func play_welcome_audio():
	# Play welcome message when game starts
	if "welcome" in feedback_audio_files and feedback_audio_files["welcome"].size() > 0:
		if has_node("Audio/WordAudio"):
			$Audio/WordAudio.stream = feedback_audio_files["welcome"][0]
			$Audio/WordAudio.play()

func play_tool_audio(tool_name):
	print("Attempting to play audio for tool: ", tool_name)
	
	if has_node("Audio/WordAudio"):
		# Stop any currently playing audio
		$Audio/WordAudio.stop()
		
		if tool_name in word_audio_files and word_audio_files[tool_name] != null:
			$Audio/WordAudio.stream = word_audio_files[tool_name]
			$Audio/WordAudio.play()
			print("✅ Playing audio for tool: " + tool_name)
		else:
			print("❌ No audio file found for tool: " + tool_name)

func play_feedback_audio(category):
	if category in feedback_audio_files and feedback_audio_files[category].size() > 0:
		var audio_streams = feedback_audio_files[category]
		var random_audio = audio_streams[randi() % audio_streams.size()]
		
		if has_node("Audio/CorrectSound"):
			$Audio/CorrectSound.stream = random_audio
			$Audio/CorrectSound.play()
			print("Playing feedback audio: ", category)

func _on_tool_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_global_mouse_position()
			var clicked_tool = find_tool_at_position(mouse_pos)
			if clicked_tool:
				# Play tool audio when clicked
				var tool_name = get_tool_name(clicked_tool)
				play_tool_audio(tool_name)
				start_dragging(clicked_tool)
		else:
			stop_dragging()

func find_tool_at_position(pos):
	var tools = [
		$ToolArea/HammerSlot,
		$ToolArea/WrenchSlot,
		$ToolArea/ScrewdriverSlot,
		$ToolArea/SawSlot
	]
	
	for tool in tools:
		if tool and pos.distance_to(tool.global_position) < 100:
			return tool
	return null

func _on_tool_hover(tool):
	if not is_dragging and not is_tool_matched(tool):
		var tween = create_tween()
		tween.tween_property(tool, "scale", Vector2(1.2, 1.2), 0.1)

func _on_tool_unhover(tool):
	if not is_dragging:
		var tween = create_tween()
		tween.tween_property(tool, "scale", Vector2(1.0, 1.0), 0.1)

func start_dragging(tool):
	if is_tool_matched(tool):
		return
		
	is_dragging = true
	dragged_tool = tool
	
	tool.modulate = Color.YELLOW
	tool.z_index = 100
	tool.scale = Vector2(1.3, 1.3)

func stop_dragging():
	if not dragged_tool:
		return
		
	var mouse_pos = get_global_mouse_position()
	var word_block = find_word_block_at_position(mouse_pos)
	
	if word_block:
		check_match(dragged_tool, word_block)
	else:
		return_to_start(dragged_tool)
	
	# Reset visual state
	dragged_tool.modulate = Color.WHITE
	dragged_tool.z_index = 0
	dragged_tool.scale = Vector2(1.0, 1.0)
	
	is_dragging = false
	dragged_tool = null

func find_word_block_at_position(pos):
	var word_blocks = [
		$WordArea/WordBlock_Hammer,
		$WordArea/WordBlock_Wrench,
		$WordArea/WordBlock_Screwdriver,
		$WordArea/WordBlock_Saw
	]
	
	for word_block in word_blocks:
		if word_block and pos.distance_to(word_block.global_position) < 100:
			return word_block
	return null

func check_match(tool, word_block):
	var tool_name = get_tool_name(tool)
	var word_name = get_word_name(word_block)
	
	if tool_name == word_name:
		create_successful_match(tool, word_block)
	else:
		show_feedback("Try again! " + tool_name.capitalize() + " doesn't match " + word_name.capitalize())
		play_feedback_audio("wrong")
		return_to_start(tool)

func create_successful_match(tool, word_block):
	# Play success audio
	play_feedback_audio("correct")
	
	# Hide the tool with a nice fade effect instead of repositioning
	var tween = create_tween()
	tween.parallel().tween_property(tool, "modulate:a", 0.0, 0.5)  # Fade out
	tween.parallel().tween_property(tool, "scale", Vector2(0.5, 0.5), 0.5)  # Shrink
	
	# Highlight the matched word block with success color
	var word_sprite = word_block.get_node_or_null("BlockSprite")
	var word_text = word_block.get_node_or_null("WordText")
	
	if word_sprite:
		word_sprite.modulate = Color(0.7, 1.0, 0.7, 1)  # Success green
	
	if word_text:
		# Make the text bolder and more visible
		word_text.modulate = Color(0.2, 0.6, 0.2, 1)  # Dark green
		word_text.add_theme_color_override("font_shadow_color", Color.WHITE)
		word_text.add_theme_constant_override("shadow_offset_x", 2)
		word_text.add_theme_constant_override("shadow_offset_y", 2)
	
	# Mark as matched
	var tool_name = get_tool_name(tool)
	matched_pairs[tool_name] = word_block
	matches_made += 1
	
	if matches_made >= total_matches:
		complete_all_matches()
	else:
		show_feedback("Perfect match! Well done!")

func complete_all_matches():
	show_feedback("OUTSTANDING WORK!\nYou're an amazing engineer!\nReady for your next challenge?")
	
	# Play celebration audio
	play_feedback_audio("encouragement")
	
	# Enable next button
	if has_node("UI/NavButtons/NextButton"):
		var next_button = $UI/NavButtons/NextButton
		next_button.disabled = false
		next_button.text = "Amazing! Next →"

func show_feedback(message):
	var instruction_text = get_node_or_null("UI/InstructionBubble/InstructionText")
	if instruction_text:
		instruction_text.text = message
		
		# Reset any previous styling and use the label's natural properties
		instruction_text.modulate = Color.WHITE  # Reset modulate
		instruction_text.add_theme_color_override("font_color", Color(0.55, 0.27, 0.07, 1))  # Brown color
		
		# Ensure proper alignment within the bubble
		instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# Reset position and size to use the label's anchors properly
		instruction_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Add some padding so text doesn't touch bubble edges
		var margin = 20
		instruction_text.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, margin)
		
		# Subtle animation that doesn't break positioning
		var original_modulate = instruction_text.modulate
		instruction_text.modulate = Color(1.2, 1.2, 1.2, 1)  # Slightly brighter
		
		var tween = create_tween()
		tween.tween_property(instruction_text, "modulate", original_modulate, 0.3)

func return_to_start(tool):
	var original_pos = original_tool_positions.get(tool, tool.global_position)
	
	var tween = create_tween()
	tween.parallel().tween_property(tool, "global_position", original_pos, 0.5)
	tween.parallel().tween_property(tool, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(tool, "modulate", Color.WHITE, 0.3)  # Reset color
	
	tool.z_index = 0

func get_tool_name(tool):
	var name = tool.name.to_lower()
	if "hammer" in name:
		return "hammer"
	elif "wrench" in name:
		return "wrench"
	elif "screwdriver" in name:
		return "screwdriver"
	elif "saw" in name:
		return "saw"
	return ""

func get_word_name(word_block):
	var name = word_block.name.to_lower()
	if "hammer" in name:
		return "hammer"
	elif "wrench" in name:
		return "wrench"
	elif "screwdriver" in name:
		return "screwdriver"
	elif "saw" in name:
		return "saw"
	return ""

func is_tool_matched(tool):
	var tool_name = get_tool_name(tool)
	return tool_name in matched_pairs

func _process(delta):
	if is_dragging and dragged_tool:
		dragged_tool.global_position = get_global_mouse_position()

# Navigation button handlers
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene1_Welcome.tscn")

func _on_next_button_pressed():
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene4_FixBridge.tscn")

# Debug function to test audio files
func test_all_audio():
	print("=== TESTING ALL TOOL AUDIO FILES ===")
	for tool_name in word_audio_files:
		if word_audio_files[tool_name] != null:
			print("✅ Audio available for: ", tool_name)
		else:
			print("❌ No audio for: ", tool_name)
	
	for category in feedback_audio_files:
		print("Feedback category '", category, "' has ", feedback_audio_files[category].size(), " files")

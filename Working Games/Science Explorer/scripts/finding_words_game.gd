extends Node2D

# Finding Words Game Script - WEB COMPATIBLE VERSION
# Uses JSON config instead of directory scanning

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/Scene1_ScienceMainMenu.tscn"
const CUTSCENE_SCENE = "res://scenes/Scene6_FindingWordsCutscene.tscn"
const NEXT_CUTSCENE = "res://scenes/Scene8_FinalCutscene.tscn"

# Available words for dig spots
var available_dig_labels = ["for", "his", "play", "started", "mother", "out", "came", "jhodk", "6th", "7", "big", "L", "just", "3"]

# Game words organized by levels
var word_levels = {
	"level_1": [],  # 2-letter words
	"level_2": [],  # 3-letter words  
	"level_3": []   # 4-letter words
}
var current_level = "level_1"
var current_word_in_level = 0

# Game state
var sight_words = []
var audio_file_paths = {}
var current_word = ""
var score = 0
var words_found = 0
var total_words_to_find = 0

# Dig spot data
var dig_spots = []
var dig_spot_data = {}  # Store word/letter data for each spot

# UI references
@onready var words_remaining_label = $UI/CountDisplayPanel/WordsRemaningLabel
@onready var play_word_button = $UI/CountDisplayPanel/PlayWordButton
@onready var score_label = $UI/ScorePanel/ScoreLabel
@onready var next_button = $UI/NavButtons/NextButton
@onready var back_button = $UI/NavButtons/BackButton
@onready var game_title = $UI/GameTitle
@onready var instruction_text = $UI/InstructionBubble/InstructionText

# Dig spot references
@onready var dig_spot1 = $"Digging Area/DigSpot1"
@onready var dig_spot2 = $"Digging Area/DigSpot2"
@onready var dig_spot3 = $"Digging Area/DigSpot3"
@onready var dig_spot4 = $"Digging Area/DigSpot4"

# Audio references
@onready var word_audio = $Audio/WordAudio
@onready var correct_sound = $Audio/CorrectSound
@onready var wrong_sound = $Audio/WrongSound
@onready var background_music = $Audio/BackgroundMusic

func _ready():
	print("Finding Words Game - WEB COMPATIBLE VERSION")
	await get_tree().process_frame
	
	# Setup proper text wrapping for labels
	setup_text_wrapping()
	
	# Setup dig spots array
	setup_dig_spots()
	
	# Connect UI signals  
	setup_ui_connections()
	
	# CHANGED: Load from JSON config instead of scanning directories
	load_audio_from_json()
	
	# Setup game if words were found
	if sight_words.size() > 0:
		setup_game()
	else:
		show_no_words_message()

func _on_tree_entered():
	"""Called when node enters scene tree - connected in scene file"""
	print("Finding Words Game scene tree entered")

func setup_text_wrapping():
	"""Setup proper text wrapping for all labels"""
	if words_remaining_label:
		words_remaining_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words_remaining_label.clip_contents = true
		words_remaining_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		words_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if instruction_text:
		instruction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_text.clip_contents = true
		instruction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if score_label:
		score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		score_label.clip_contents = true
		score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func setup_dig_spots():
	"""Setup dig spots array"""
	dig_spots = [dig_spot1, dig_spot2, dig_spot3, dig_spot4]
	
	for i in range(dig_spots.size()):
		var spot = dig_spots[i]
		if spot:
			print("Dig spot ", i+1, " ready at: ", spot.global_position)

func setup_ui_connections():
	"""Connect UI button signals"""
	if play_word_button:
		play_word_button.pressed.connect(_on_play_word_button_pressed)
		print("Connected play button")
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		print("Connected back button")
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		print("Connected next button")

# Manual click detection using global input
func _input(event):
	"""Handle all input manually"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_global_click(event.global_position)

func handle_global_click(click_pos: Vector2):
	"""Handle clicks by checking which dig spot was clicked"""
	print("Click detected at: ", click_pos)
	
	# Check each dig spot
	for i in range(dig_spots.size()):
		var spot = dig_spots[i]
		if spot and is_click_in_dig_spot(click_pos, spot, i):
			print("Clicked on dig spot ", i+1)
			handle_dig_spot_selection(spot, i)
			return
	
	print("Click didn't hit any dig spot")

func is_click_in_dig_spot(click_pos: Vector2, spot: Area2D, spot_index: int) -> bool:
	"""Check if click position is within a dig spot's collision area"""
	var collision = spot.get_node("Hole" + str(spot_index+1) + "Collision")
	if not collision or not collision.shape:
		return false
	
	# Get the collision shape (should be CircleShape2D with radius 30)
	var shape = collision.shape as CircleShape2D
	if not shape:
		return false
	
	# Calculate the center of the collision circle in global coordinates
	var spot_global_pos = spot.global_position
	var collision_offset = collision.position
	var circle_center = spot_global_pos + collision_offset
	
	# Check if click is within the circle
	var distance = click_pos.distance_to(circle_center)
	var is_inside = distance <= shape.radius
	
	print("  Spot ", spot_index+1, ":")
	print("    Circle center: ", circle_center)
	print("    Click distance: ", distance)
	print("    Circle radius: ", shape.radius)
	print("    Inside? ", is_inside)
	
	return is_inside

#func load_audio_from_json():
	#"""Load audio files from JSON configuration - WEB COMPATIBLE"""
	#print("📖 Loading audio from JSON config...")
	#
	#sight_words.clear()
	#audio_file_paths.clear()
	#word_levels.clear()
	#
	#var config_path = "res://word_config.json"
	#
	#if not FileAccess.file_exists(config_path):
		#print("❌ word_config.json not found!")
		#print("🛠️  Run the audio generator tool first:")
		#print("   1. Create res://tools/audio_generator.gd")
		#print("   2. Run it in Godot Editor (Tools > Execute Script)")
		#show_no_words_message()
		#return
	#
	#var file = FileAccess.open(config_path, FileAccess.READ)
	#if not file:
		#print("❌ Could not open word_config.json")
		#show_no_words_message()
		#return
	#
	#var json_text = file.get_as_text()
	#file.close()
	#
	#var json = JSON.new()
	#var parse_result = json.parse(json_text)
	#
	#if parse_result != OK:
		#print("❌ Invalid JSON in word_config.json")
		#print("🛠️  Re-run the audio generator tool")
		#show_no_words_message()
		#return
	#
	#var config = json.data
	#
	## Extract metadata
	#var metadata = config.get("metadata", {})
	#print("📊 Config generated: ", metadata.get("generated_at", "unknown"))
	#print("📦 Total files available: ", metadata.get("total_files", 0))
	#
	## Load each level
	#var levels_data = config.get("levels", {})
	#
	#for level_name in levels_data:
		#word_levels[level_name] = []
		#var level_info = levels_data[level_name]
		#var words_in_level = level_info.get("words", {})
		#
		#print("📁 Loading ", level_info.get("description", level_name), "...")
		#
		## Load each word in this level
		#for word in words_in_level:
			#var audio_path = words_in_level[word]
			#
			## Verify the audio file exists
			#if ResourceLoader.exists(audio_path):
				#sight_words.append(word)
				#audio_file_paths[word] = audio_path
				#word_levels[level_name].append(word)
				#print("  ✅ ", word, " -> ", audio_path.get_file())
			#else:
				#print("  ❌ Missing: ", word, " -> ", audio_path)
	#
	## Limit each level to 6 words for testing
	#word_levels["level_1"] = word_levels["level_1"].slice(0, 6)
	#word_levels["level_2"] = word_levels["level_2"].slice(0, 6)
	#word_levels["level_3"] = word_levels["level_3"].slice(0, 6)
	#
	## Summary
	#var total_loaded = sight_words.size()
	#print("🎉 Successfully loaded ", total_loaded, " words!")
	#print("   📝 Level 1 (2-letter): ", word_levels.get("level_1", []).size(), " words")
	#print("   📚 Level 2 (3-letter): ", word_levels.get("level_2", []).size(), " words")
	#print("   🎓 Level 3 (4-letter): ", word_levels.get("level_3", []).size(), " words")
	#
	#if total_loaded == 0:
		#print("⚠️ No audio files loaded! Check your file paths.")
		#show_no_words_message()

func load_audio_from_json():
	"""Load audio files from JSON configuration - WEB COMPATIBLE"""
	print("📖 Loading audio from JSON config...")
	
	sight_words.clear()
	audio_file_paths.clear()
	word_levels.clear()
	
	# Initialize empty levels
	word_levels["level_1"] = []
	word_levels["level_2"] = []
	word_levels["level_3"] = []
	
	var config_path = "res://word_config.json"
	
	if not FileAccess.file_exists(config_path):
		print("❌ word_config.json not found!")
		print("🛠️  Run the audio generator tool first:")
		print("   1. Create res://tools/audio_generator.gd")
		print("   2. Run it in Godot Editor (Tools > Execute Script)")
		show_no_words_message()
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("❌ Could not open word_config.json")
		show_no_words_message()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("❌ Invalid JSON in word_config.json")
		print("🛠️  Re-run the audio generator tool")
		show_no_words_message()
		return
	
	var config = json.data
	
	# Extract metadata
	var metadata = config.get("metadata", {})
	print("📊 Config generated: ", metadata.get("generated_at", "unknown"))
	print("📦 Total files available: ", metadata.get("total_files", 0))
	
	# Load each level
	var levels_data = config.get("levels", {})
	
	for level_name in levels_data:
		var level_info = levels_data[level_name]
		var words_in_level = level_info.get("words", {})
		
		print("📁 Loading ", level_info.get("description", level_name), "...")
		
		# Load each word in this level
		for word in words_in_level:
			var audio_path = words_in_level[word]
			
			# Verify the audio file exists
			if ResourceLoader.exists(audio_path):
				sight_words.append(word)
				audio_file_paths[word] = audio_path
				word_levels[level_name].append(word)
				print("  ✅ ", word, " -> ", audio_path.get_file())
			else:
				print("  ❌ Missing: ", word, " -> ", audio_path)
	
	# Summary
	var total_loaded = sight_words.size()
	print("🎉 Successfully loaded ", total_loaded, " words!")
	print("   📝 Level 1 (2-letter): ", word_levels.get("level_1", []).size(), " words")
	print("   📚 Level 2 (3-letter): ", word_levels.get("level_2", []).size(), " words")
	print("   🎓 Level 3 (4-letter): ", word_levels.get("level_3", []).size(), " words")
	
	if total_loaded == 0:
		print("⚠️ No audio files loaded! Check your file paths.")
		show_no_words_message()

func setup_game():
	"""Setup the game with found words"""
	print("Setting up Finding Words game...")
	
	# Initialize level system
	current_level = "level_1"
	current_word_in_level = 0
	words_found = 0
	
	# Check if we have words
	if word_levels["level_1"].size() == 0:
		print("No words found for Level 1!")
		show_no_words_message()
		return
	
	# Initialize game state
	score = 0
	
	# Setup first level
	start_level(current_level)
	
	# Update UI
	update_score_display()
	update_words_remaining_display()
	
	if next_button:
		next_button.disabled = true

func start_level(level_name: String):
	"""Start a specific level"""
	current_level = level_name
	current_word_in_level = 0
	words_found = 0
	
	var level_num = get_level_number(level_name)
	var word_count = word_levels[level_name].size()
	total_words_to_find = min(4, word_count)  # Max 4 words per round (4 dig spots)
	
	print("=== STARTING LEVEL ", level_num, " ===")
	print("Available words: ", word_count)
	print("Words to find this round: ", total_words_to_find)
	
	# Update UI
	update_level_title()
	update_instruction_text_for_level()
	
	# Load first word (this will setup the dig spots automatically)
	load_next_word()

func setup_round_with_distractors():
	"""Setup current word with distractors"""
	if current_word == "":
		print("ERROR: No current word set!")
		return
		
	# Clear previous data
	dig_spot_data.clear()
	
	# Get distractors (not the current word)
	var level_words = word_levels[current_level]
	var distractors = []
	
	# Add some other words from same level as distractors
	for word in level_words:
		if word != current_word and distractors.size() < 2:
			distractors.append(word)
	
	# Add some random distractors if needed
	var random_distractors = available_dig_labels.duplicate()
	random_distractors.shuffle()
	
	for distractor in random_distractors:
		if distractor != current_word and distractor not in distractors and distractors.size() < 3:
			distractors.append(distractor)
	
	# Create the final mix: 1 target word + 3 distractors
	var all_labels = [current_word]
	for i in range(min(3, distractors.size())):
		all_labels.append(distractors[i])
	
	# Shuffle so target word isn't always in same position
	all_labels.shuffle()
	
	print("Round setup for word '", current_word.to_upper(), "':")
	print("  Target: ", current_word)
	print("  Distractors: ", distractors.slice(0, 3))
	print("  Mixed labels: ", all_labels)
	
	# Assign to dig spots
	for i in range(min(4, all_labels.size())):
		var spot = dig_spots[i]
		var label = all_labels[i]
		var is_target = (label == current_word)
		
		# Store data
		dig_spot_data[spot] = {
			"label": label,
			"is_target": is_target,
			"found": false
		}
		
		# Update visual label with better text handling
		var label_node = spot.get_node("Hole" + str(i+1) + "Label")
		if label_node:
			label_node.text = label.to_upper()
			
			# Disable text wrapping for dig spot labels to prevent word breaking
			label_node.autowrap_mode = TextServer.AUTOWRAP_OFF
			label_node.clip_contents = false
			
			# Adjust font size for longer words
			if label.length() > 3:
				label_node.add_theme_font_size_override("font_size", 20)  # Smaller for 4+ letter words
			elif label.length() > 2:
				label_node.add_theme_font_size_override("font_size", 28)  # Medium for 3 letter words
			else:
				label_node.add_theme_font_size_override("font_size", 32)  # Normal for 2 letter words
			
			print("Set label for spot ", i+1, ": ", label.to_upper())
		else:
			print("WARNING: Could not find label node for spot ", i+1)
		
		# Make spot visible and clickable
		spot.visible = true
		
		print("Dig Spot ", i+1, ": ", label.to_upper(), " (", "TARGET" if is_target else "DISTRACTOR", ")")

func load_next_word():
	"""Load the next word to find"""
	var level_words = word_levels[current_level]
	
	if current_word_in_level < level_words.size() and current_word_in_level < total_words_to_find:
		current_word = level_words[current_word_in_level]
		
		print("=== FIND WORD ", current_word_in_level + 1, " OF ", total_words_to_find, " ===")
		print("Listen for: ", current_word.to_upper())
		
		# Setup dig spots for this specific word
		setup_round_with_distractors()
		
		# Update UI
		update_words_remaining_display()
		
		# Auto-play word after short delay
		await get_tree().create_timer(1.0).timeout
		play_word_audio()
		
	else:
		# Level complete
		level_complete()

func update_level_title():
	"""Update title with current level info"""
	if game_title:
		var level_num = get_level_number(current_level)
		game_title.text = "FINDING WORDS - LEVEL " + level_num

func update_instruction_text_for_level():
	"""Update instruction text based on current level"""
	if instruction_text:
		var level_num = get_level_number(current_level)
		var difficulty = ""
		
		match current_level:
			"level_1":
				difficulty = "Easy 2-letter words"
			"level_2":
				difficulty = "Medium 3-letter words"
			"level_3":
				difficulty = "Hard 4-letter words"
		
		instruction_text.text = "Level " + level_num + ": " + difficulty + "!\nListen and click the word you hear!"

func update_words_remaining_display():
	"""Update words remaining display"""
	if words_remaining_label:
		var remaining = total_words_to_find - words_found
		words_remaining_label.text = str(remaining) + " Words Remaining"

func get_level_number(level_name: String) -> String:
	"""Get display number for level"""
	match level_name:
		"level_1": return "1"
		"level_2": return "2" 
		"level_3": return "3"
		_: return "?"

func handle_dig_spot_selection(spot: Area2D, spot_index: int):
	"""Handle when a dig spot is selected"""
	print("=== HANDLING DIG SPOT SELECTION ===")
	print("Spot: ", spot)
	print("Spot index: ", spot_index)
	
	if spot not in dig_spot_data:
		print("ERROR: Spot data not found for spot ", spot_index + 1)
		return
	
	var spot_data = dig_spot_data[spot]
	var selected_label = spot_data["label"]
	var is_target = spot_data["is_target"]
	
	print("Selected: ", selected_label.to_upper(), " (looking for: ", current_word.to_upper(), ")")
	print("Is target: ", is_target)
	
	if is_target:
		# Correct word found!
		handle_correct_selection(spot, spot_index)
	else:
		# Wrong selection
		handle_wrong_selection(spot, spot_index)

func handle_correct_selection(spot: Area2D, spot_index: int):
	"""Handle correct word selection"""
	var spot_data = dig_spot_data[spot]
	print("🎉 CORRECT! Found: ", current_word.to_upper())
	
	# Mark as found
	spot_data["found"] = true
	words_found += 1
	
	# Award points based on word length
	var points = current_word.length() * 10  # 10 points per letter
	score += points
	print("Score increased by ", points, " points! New score: ", score)
	update_score_display()
	
	# Visual feedback - make the correct spot green
	var sprite = spot.get_node("Hole" + str(spot_index+1) + "Sprite")
	if sprite:
		sprite.modulate = Color.GREEN
	
	# Hide/disable other spots to prevent confusion
	for i in range(dig_spots.size()):
		if i != spot_index:
			var other_spot = dig_spots[i]
			var other_sprite = other_spot.get_node("Hole" + str(i+1) + "Sprite")
			if other_sprite:
				other_sprite.modulate = Color.GRAY
	
	# Play correct sound
	if correct_sound and correct_sound.stream:
		correct_sound.play()
	
	# Update UI
	if words_remaining_label:
		words_remaining_label.text = "Perfect! +" + str(points) + " points"
		words_remaining_label.modulate = Color.GREEN
	
	# Wait, then continue
	await get_tree().create_timer(2.5).timeout
	
	# Reset visual feedback
	reset_dig_spot_visuals()
	
	# Reset label color
	if words_remaining_label:
		words_remaining_label.modulate = Color.WHITE
	
	# Move to next word
	current_word_in_level += 1
	load_next_word()

func reset_dig_spot_visuals():
	"""Reset all dig spot visual states"""
	for i in range(dig_spots.size()):
		var spot = dig_spots[i]
		var sprite = spot.get_node("Hole" + str(i+1) + "Sprite")
		if sprite:
			sprite.modulate = Color.WHITE

func handle_wrong_selection(spot: Area2D, spot_index: int):
	"""Handle wrong selection"""
	var selected = dig_spot_data[spot]["label"]
	print("❌ Wrong! Selected: ", selected.to_upper(), " but looking for: ", current_word.to_upper())
	
	# Visual feedback
	var sprite = spot.get_node("Hole" + str(spot_index+1) + "Sprite")
	if sprite:
		sprite.modulate = Color.RED
	
	# Play wrong sound
	if wrong_sound and wrong_sound.stream:
		wrong_sound.play()
	
	# Update UI
	if words_remaining_label:
		words_remaining_label.text = "Try again! Listen carefully..."
		words_remaining_label.modulate = Color.RED
	
	# Wait, then reset
	await get_tree().create_timer(1.5).timeout
	
	# Reset visual
	if sprite:
		sprite.modulate = Color.WHITE
	if words_remaining_label:
		words_remaining_label.modulate = Color.WHITE
		update_words_remaining_display()
	
	# Replay the word
	await get_tree().create_timer(0.5).timeout
	play_word_audio()

func level_complete():
	"""Handle level completion"""
	var level_num = get_level_number(current_level)
	print("=== LEVEL ", level_num, " COMPLETE! ===")
	
	# Update UI
	if game_title:
		game_title.text = "LEVEL " + level_num + " COMPLETE!"
	if words_remaining_label:
		words_remaining_label.text = "Level Mastered!"
		words_remaining_label.modulate = Color.GOLD
	
	await get_tree().create_timer(3.0).timeout
	
	# Move to next level or complete game
	move_to_next_level()

func move_to_next_level():
	"""Move to the next level"""
	var level_order = ["level_1", "level_2", "level_3"]
	var current_index = level_order.find(current_level)
	
	if current_index < level_order.size() - 1:
		var next_level = level_order[current_index + 1]
		
		if word_levels[next_level].size() > 0:
			start_level(next_level)
		else:
			print("No words in ", next_level, ", skipping...")
			current_level = next_level
			move_to_next_level()
	else:
		game_complete()

func game_complete():
	"""Handle game completion"""
	print("=== FINDING WORDS COMPLETE! ===")
	
	if game_title:
		game_title.text = "WORD MASTER!"
	if words_remaining_label:
		words_remaining_label.text = "All Words Found!"
		words_remaining_label.modulate = Color.GOLD
	if instruction_text:
		instruction_text.text = "Congratulations! You've mastered word finding!"
	
	if next_button:
		next_button.disabled = false

func show_no_words_message():
	"""Show message when no words found"""
	print("No audio files loaded from config!")
	
	if words_remaining_label:
		words_remaining_label.text = "No words found!"
	if game_title:
		game_title.text = "NO AUDIO FILES FOUND"
	if instruction_text:
		instruction_text.text = "Run the audio generator tool first!\nTools > Execute Script"
	if play_word_button:
		play_word_button.disabled = true

func _on_play_word_button_pressed():
	"""Play current word audio"""
	print("Play button pressed for: ", current_word.to_upper())
	play_word_audio()

func play_word_audio():
	"""Play the audio for current word"""
	if current_word != "" and current_word in audio_file_paths:
		var audio_path = audio_file_paths[current_word]
		print("Playing audio for: ", current_word.to_upper())
		
		if ResourceLoader.exists(audio_path):
			var audio_stream = load(audio_path)
			if word_audio and audio_stream:
				word_audio.stream = audio_stream
				word_audio.play()
				print("Audio playing successfully")
		else:
			print("Audio file not found: ", audio_path)
	else:
		print("No audio available for current word: ", current_word)

func update_score_display():
	"""Update score display"""
	if score_label:
		score_label.text = "Score: " + str(score)
		print("Updated score display: ", score)

# Navigation functions
func _on_back_button_pressed():
	"""Go back to cutscene"""
	print("Going back to cutscene")
	if background_music and background_music.playing:
		background_music.stop()
	
	# Check if cutscene exists, otherwise go to main menu
	if ResourceLoader.exists(CUTSCENE_SCENE):
		get_tree().change_scene_to_file(CUTSCENE_SCENE)
	else:
		print("Cutscene not found, going to main menu")
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_next_button_pressed():
	"""Go to next scene"""
	print("Going to next scene")
	if background_music and background_music.playing:
		background_music.stop()
	
	if ResourceLoader.exists(NEXT_CUTSCENE):
		get_tree().change_scene_to_file(NEXT_CUTSCENE)
	else:
		print("Next scene not available")
		_on_back_button_pressed()

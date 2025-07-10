extends Node2D

# Making Words Game Script - Fixed Version
# Dynamic bottle assignment with mixed letters and proper text wrapping

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/Scene1_ScienceMainMenu.tscn"
const NEXT_CUTSCENE = "res://scenes/Scene4_LabellingPlantsCutscene.tscn"

# Audio file paths to check
var audio_directories = [
	"res://Assets/Audio/First Grade Words/",
	"res://Assets/Audio/Words/",
	"res://Assets/Audio/"
]

# Available letters for bottles (mix of common and uncommon letters)
var available_letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

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
var bottle_letters = {}
var current_word = ""
var player_spelling = ""
var score = 0

# Drag and drop
var dragging_bottle = null
var drag_offset = Vector2()
var original_positions = {}

# UI references
@onready var current_word_label = $UI/WordDisplayPanel/CurrentWordLabel
@onready var play_word_button = $UI/WordDisplayPanel/PlayWordButton
@onready var mixing_area = $UI/MixingArea
@onready var spelling_display = $UI/MixingArea/SpellingDisplay
@onready var score_label = $UI/ScorePanel/ScoreLabel
@onready var next_button = $UI/NavButtons/NextButton
@onready var back_button = $UI/NavButtons/BackButton
@onready var game_title = $UI/GameTitle
@onready var instruction_text = $UI/InstructionBubble/InstructionText

# Bottle references
@onready var bottle_a = $BottleArea/BottleA
@onready var bottle_e = $BottleArea/BottleE
@onready var bottle_t = $BottleArea/BottleT
@onready var bottle_c = $BottleArea/BottleC

# Audio references
@onready var word_audio = $Audio/WordAudio
@onready var correct_sound = $Audio/CorrectSound
@onready var wrong_sound = $Audio/WrongSound
@onready var background_music = $Audio/BackgroundMusic

# Drop zone reference
@onready var mixing_drop_zone = $MixingDropZone

func _ready():
	print("Making Words Game - PROTOTYPE VERSION (6 words per level)")
	await get_tree().process_frame
	
	# Setup proper text wrapping for labels
	setup_text_wrapping()
	
	# Scan for audio files and build word list
	scan_audio_files()
	
	# Setup game if words were found
	if sight_words.size() > 0:
		setup_game()
	else:
		show_no_words_message()

func setup_text_wrapping():
	"""Setup proper text wrapping for all labels"""
	if current_word_label:
		current_word_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_word_label.clip_contents = true
		current_word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		current_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if spelling_display:
		spelling_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spelling_display.clip_contents = true
		spelling_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		spelling_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
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

func scan_audio_files():
	"""Scan audio directories for 2-4 letter word files"""
	print("Scanning audio directories for 2-4 letter words...")
	
	# Clear existing data
	sight_words.clear()
	audio_file_paths.clear()
	
	# Check each directory
	for directory in audio_directories:
		print("Checking directory: ", directory)
		scan_directory(directory)
	
	# Organize words by difficulty
	organize_words_by_difficulty()

func scan_directory(dir_path: String):
	"""Scan a specific directory for audio files"""
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Directory does not exist: ", dir_path)
		return
	
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				# Check if it's an audio file
				if is_audio_file(file_name):
					var word = extract_word_from_filename(file_name)
					
					# Check if it's 2-4 letters long
					if word.length() >= 2 and word.length() <= 4:
						sight_words.append(word)
						audio_file_paths[word] = dir_path + file_name
						print("Found ", word.length(), "-letter word: ", word, " -> ", file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

func is_audio_file(filename: String) -> bool:
	"""Check if file is an audio file"""
	var audio_extensions = [".wav", ".ogg", ".mp3"]
	var lower_filename = filename.to_lower()
	
	for ext in audio_extensions:
		if lower_filename.ends_with(ext):
			return true
	
	return false

func extract_word_from_filename(filename: String) -> String:
	"""Extract word from filename (remove extension)"""
	var word = filename
	
	# Remove common audio extensions
	var extensions = [".wav", ".ogg", ".mp3", ".WAV", ".OGG", ".MP3"]
	for ext in extensions:
		if word.ends_with(ext):
			word = word.substr(0, word.length() - ext.length())
			break
	
	# Convert to lowercase for consistency
	return word.to_lower()

func organize_words_by_difficulty():
	"""Organize words by length into levels - PROTOTYPE: 6 words per level"""
	word_levels["level_1"].clear()
	word_levels["level_2"].clear()
	word_levels["level_3"].clear()
	
	# Temporary arrays to collect all words by length
	var temp_level_1 = []
	var temp_level_2 = []
	var temp_level_3 = []
	
	# Collect all words by length
	for word in sight_words:
		if word.length() == 2:
			temp_level_1.append(word)
		elif word.length() == 3:
			temp_level_2.append(word)
		elif word.length() == 4:
			temp_level_3.append(word)
	
	# Sort each level alphabetically
	temp_level_1.sort()
	temp_level_2.sort()
	temp_level_3.sort()
	
	# PROTOTYPE: Take only first 6 words from each level
	var words_per_level = 6
	
	# Level 1 (2-letter words)
	for i in range(min(words_per_level, temp_level_1.size())):
		word_levels["level_1"].append(temp_level_1[i])
	
	# Level 2 (3-letter words)
	for i in range(min(words_per_level, temp_level_2.size())):
		word_levels["level_2"].append(temp_level_2[i])
	
	# Level 3 (4-letter words)
	for i in range(min(words_per_level, temp_level_3.size())):
		word_levels["level_3"].append(temp_level_3[i])
	
	print("=== PROTOTYPE LEVEL ORGANIZATION (6 WORDS PER LEVEL) ===")
	print("Total words found:")
	print("  2-letter words available: ", temp_level_1.size(), " (using first 6)")
	print("  3-letter words available: ", temp_level_2.size(), " (using first 6)")
	print("  4-letter words available: ", temp_level_3.size(), " (using first 6)")
	print("")
	print("Selected words for prototype:")
	print("Level 1 (2-letter): ", word_levels["level_1"].size(), " words - ", word_levels["level_1"])
	print("Level 2 (3-letter): ", word_levels["level_2"].size(), " words - ", word_levels["level_2"])
	print("Level 3 (4-letter): ", word_levels["level_3"].size(), " words - ", word_levels["level_3"])
	print("=== PROTOTYPE TOTAL: ", word_levels["level_1"].size() + word_levels["level_2"].size() + word_levels["level_3"].size(), " WORDS ===")
	
	# Show skipped words for reference
	if temp_level_1.size() > words_per_level:
		print("Skipped 2-letter words: ", temp_level_1.slice(words_per_level))
	if temp_level_2.size() > words_per_level:
		print("Skipped 3-letter words: ", temp_level_2.slice(words_per_level))
	if temp_level_3.size() > words_per_level:
		print("Skipped 4-letter words: ", temp_level_3.slice(words_per_level))

func setup_game():
	"""Setup the game with found words"""
	print("Setting up game with levels...")
	
	# Initialize level system
	current_level = "level_1"
	current_word_in_level = 0
	
	# Check if we have words for level 1
	if word_levels["level_1"].size() == 0:
		print("No words found for Level 1!")
		show_no_words_message()
		return
	
	# Check if UI elements exist
	if not current_word_label or not spelling_display or not score_label:
		print("ERROR: UI elements not found!")
		return
	
	# Initialize game state
	score = 0
	player_spelling = ""
	
	# Store bottle positions
	store_original_positions()
	
	# Connect bottle signals
	setup_bottle_interactions()
	
	# Setup first level
	start_level(current_level)
	
	# Update UI
	update_score_display()
	update_spelling_display()
	
	if next_button:
		next_button.disabled = true

func start_level(level_name: String):
	"""Start a specific level"""
	current_level = level_name
	current_word_in_level = 0
	
	var level_num = get_level_number(level_name)
	var word_count = word_levels[level_name].size()
	
	print("=== STARTING LEVEL ", level_num, " (", word_count, " words) ===")
	
	# Update UI
	update_level_title()
	update_instruction_text_for_level()
	
	# Start first word of the level
	load_next_word_in_level()
	
	# Auto-play the first word
	await get_tree().create_timer(1.5).timeout
	if has_words_in_current_level():
		auto_play_next_word()

func setup_bottles_for_current_word():
	"""Setup bottles with mixed letters for the current word"""
	if current_word == "":
		return false
	
	# Get unique letters from current word
	var word_letters = get_unique_letters_in_word(current_word)
	
	# Create a mix of letters: include word letters + some random letters
	var mixed_letters = []
	
	# Add word letters (the ones needed to spell the word)
	for letter in word_letters:
		mixed_letters.append(letter.to_upper())
	
	# Add random letters to fill remaining bottles (up to 4 total)
	# These are "distractor" letters that are NOT in the target word
	var remaining_slots = 4 - mixed_letters.size()
	var random_letters = get_random_letters_not_in_word(current_word, remaining_slots)
	
	for letter in random_letters:
		mixed_letters.append(letter.to_upper())
	
	# Shuffle the letters so word letters aren't always in the same bottle positions
	# This means players can't memorize "bottle 1 always has the first letter"
	mixed_letters.shuffle()
	
	# Assign mixed letters to bottles
	var bottles = [bottle_a, bottle_e, bottle_t, bottle_c]
	var bottle_labels = [
		$BottleArea/BottleA/BottleALabel,
		$BottleArea/BottleE/BottleELabel,
		$BottleArea/BottleT/BottleTLabel,
		$BottleArea/BottleC/BottleCLabel
	]
	
	bottle_letters.clear()
	
	# Assign mixed letters to bottles
	for i in range(4):
		var bottle = bottles[i]
		var label = bottle_labels[i]
		
		if i < mixed_letters.size():
			# Assign letter to bottle
			var letter = mixed_letters[i]
			bottle_letters[bottle] = letter.to_lower()
			if label:
				label.text = letter.to_upper()
			if bottle:
				bottle.visible = true
		else:
			# Hide unused bottles
			if bottle:
				bottle.visible = false
	
	print("Word '", current_word.to_upper(), "' - Challenge Setup:")
	print("  Target word letters: ", word_letters)
	print("  Mixed bottle letters: ", mixed_letters)
	print("  Player must find: ", word_letters, " and ignore distractors!")
	
	return true

func get_unique_letters_in_word(word: String) -> Array:
	"""Get unique letters in a word"""
	var letters = []
	for letter in word:
		if letter not in letters:
			letters.append(letter)
	return letters

func get_random_letters_not_in_word(word: String, count: int) -> Array:
	"""Get random letters that are NOT in the word"""
	var word_letters = []
	for letter in word:
		if letter.to_upper() not in word_letters:
			word_letters.append(letter.to_upper())
	
	var excluded_letters = word_letters.duplicate()
	var random_letters = []
	
	# Get letters that are not in the word
	var available_for_random = []
	for letter in available_letters:
		if letter not in excluded_letters:
			available_for_random.append(letter)
	
	# Pick random letters
	available_for_random.shuffle()
	for i in range(min(count, available_for_random.size())):
		random_letters.append(available_for_random[i])
	
	return random_letters

func update_instruction_text_for_level():
	"""Update instruction text based on current level"""
	if instruction_text:
		var level_num = get_level_number(current_level)
		var level_description = ""
		
		match current_level:
			"level_1":
				level_description = "Easy 2-letter words!"
			"level_2":
				level_description = "Medium 3-letter words!"
			"level_3":
				level_description = "Hard 4-letter words!"
		
		instruction_text.text = "Level " + level_num + ": " + level_description + "\nFind the right letters to spell words!"

func has_words_in_current_level() -> bool:
	"""Check if current level has words"""
	return word_levels[current_level].size() > 0

func load_next_word_in_level():
	"""Load the next word in the current level"""
	var level_words = word_levels[current_level]
	
	if current_word_in_level < level_words.size():
		current_word = level_words[current_word_in_level]
		
		# Setup bottles with mixed letters for this word
		if not setup_bottles_for_current_word():
			print("Cannot setup bottles for word: ", current_word)
			# Skip this word
			current_word_in_level += 1
			load_next_word_in_level()
			return
		
		if current_word_label:
			current_word_label.text = "Get Ready!"
		player_spelling = ""
		update_spelling_display()
		clear_mixing_area()
		
		print("=== LEVEL ", get_level_number(current_level), " - WORD ", current_word_in_level + 1, " OF ", level_words.size(), " ===")
		print("Current word: ", current_word.to_upper(), " (", current_word.length(), " letters)")
		print("Mixed bottle challenge: Find the right letters!")
		print("=====================================")
		
		# Update title with level and word progress
		update_level_title()
		
		# Keep instruction text consistent for the level
		update_instruction_text_for_level()
		
	else:
		# Level complete, move to next level
		level_complete()

func level_complete():
	"""Handle level completion"""
	var level_num = get_level_number(current_level)
	print("=== LEVEL ", level_num, " MASTERED! (6/6 words) ===")
	
	# Update title to show level complete
	if game_title:
		game_title.text = "LEVEL " + level_num + " MASTERED!"
	
	# Update instruction text for level completion
	if instruction_text:
		var next_level_num = str(int(level_num) + 1)
		if int(level_num) < 3:
			instruction_text.text = "Great mixing! Ready for Level " + next_level_num + "?"
		else:
			instruction_text.text = "All levels mastered! What's next?"
	
	# Show level complete message
	if current_word_label:
		current_word_label.text = "Level " + level_num + " Mastered!"
		current_word_label.modulate = Color.GOLD
	
	await get_tree().create_timer(3.0).timeout
	
	# Reset label color
	if current_word_label:
		current_word_label.modulate = Color.WHITE
	
	# Move to next level
	move_to_next_level()

func move_to_next_level():
	"""Move to the next level"""
	var level_order = ["level_1", "level_2", "level_3"]
	var current_index = level_order.find(current_level)
	
	if current_index < level_order.size() - 1:
		var next_level = level_order[current_index + 1]
		
		# Check if next level has words
		if word_levels[next_level].size() > 0:
			var next_level_num = get_level_number(next_level)
			print("Moving to Level ", next_level_num)
			
			# Update UI for level transition
			if game_title:
				game_title.text = "PREPARING LEVEL " + next_level_num
			if instruction_text:
				var difficulty_desc = ""
				match next_level:
					"level_2":
						difficulty_desc = "3-letter word challenges!"
					"level_3":
						difficulty_desc = "4-letter word mastery!"
				instruction_text.text = "Get ready for " + difficulty_desc
			
			await get_tree().create_timer(2.0).timeout
			
			start_level(next_level)
		else:
			print("No words in ", next_level, ", skipping...")
			# Try next level
			current_level = next_level
			move_to_next_level()
	else:
		# All levels complete
		game_complete()

func game_complete():
	"""Handle game completion"""
	print("=== WORD MIXING COMPLETE! ===")
	print("Words mastered: 18 total (6 per level)")
	print("Final Score: ", score)
	
	# Update UI for game completion
	if game_title:
		game_title.text = "WORD MIXING MASTERED!"
	if instruction_text:
		instruction_text.text = "Excellent! You've learned to mix letters into words!"
	if current_word_label:
		current_word_label.text = "Master Scientist!"
		current_word_label.modulate = Color.GOLD
	if spelling_display:
		spelling_display.text = "🧪 WORD EXPERT! 🧪"
		spelling_display.modulate = Color.GOLD
	
	# Show completion message and next game hint
	await get_tree().create_timer(2.0).timeout
	
	if instruction_text:
		instruction_text.text = "Ready for your next scientific adventure?"
	
	if next_button:
		next_button.disabled = false

func get_level_number(level_name: String) -> String:
	"""Get display number for level"""
	match level_name:
		"level_1":
			return "1"
		"level_2":
			return "2"
		"level_3":
			return "3"
		_:
			return "?"

func update_level_title():
	"""Update title with current level info"""
	if game_title:
		var level_num = get_level_number(current_level)
		var level_words = word_levels[current_level]
		var word_progress = str(current_word_in_level + 1) + "/" + str(level_words.size())
		
		game_title.text = "LEVEL " + level_num + " - WORD " + word_progress

func show_no_words_message():
	"""Show message when no words found"""
	print("No 2-4 letter word audio files found!")
	
	if current_word_label:
		current_word_label.text = "No words found!"
	if game_title:
		game_title.text = "NO AUDIO FILES FOUND"
	
	if play_word_button:
		play_word_button.disabled = true

func store_original_positions():
	"""Store original bottle positions"""
	if bottle_a:
		original_positions[bottle_a] = bottle_a.global_position
	if bottle_e:
		original_positions[bottle_e] = bottle_e.global_position
	if bottle_t:
		original_positions[bottle_t] = bottle_t.global_position
	if bottle_c:
		original_positions[bottle_c] = bottle_c.global_position

func setup_bottle_interactions():
	"""Connect bottle drag/drop signals"""
	if bottle_a:
		bottle_a.input_event.connect(_on_bottle_input_event.bind(bottle_a))
	if bottle_e:
		bottle_e.input_event.connect(_on_bottle_input_event.bind(bottle_e))
	if bottle_t:
		bottle_t.input_event.connect(_on_bottle_input_event.bind(bottle_t))
	if bottle_c:
		bottle_c.input_event.connect(_on_bottle_input_event.bind(bottle_c))

func clear_mixing_area():
	"""Reset all bottles to original positions"""
	for bottle in original_positions:
		if bottle:
			bottle.global_position = original_positions[bottle]

func _on_play_word_button_pressed():
	"""Play the current word's audio (manual override)"""
	print("Manual play button pressed for: ", current_word)
	if current_word_label:
		current_word_label.text = current_word.to_upper()
	
	# Show instructions for this specific word
	show_word_instructions()
	
	play_word_audio()
	
	print("🎯 Ready to spell: ", current_word.to_upper())

func play_word_audio():
	"""Play the audio file for the current word"""
	if current_word in audio_file_paths:
		var audio_path = audio_file_paths[current_word]
		print("Loading audio from: ", audio_path)
		
		if ResourceLoader.exists(audio_path):
			var audio_stream = load(audio_path)
			if word_audio and audio_stream:
				word_audio.stream = audio_stream
				word_audio.play()
				print("Playing audio for: ", current_word)
		else:
			print("Audio file not found: ", audio_path)

func auto_play_next_word():
	"""Automatically play the next word without user interaction"""
	if has_words_in_current_level() and current_word_in_level < word_levels[current_level].size():
		print("Auto-playing next word: ", current_word.to_upper())
		
		# Show the word automatically
		if current_word_label:
			current_word_label.text = current_word.to_upper()
		
		# Show instructions automatically in console
		show_word_instructions()
		
		# Play audio automatically
		play_word_audio()
		
		print("🎯 Ready to spell: ", current_word.to_upper())
		print("💡 Find the right letters from the mixed bottles!")
	else:
		print("No more words in current level or level complete")

func show_word_instructions():
	"""Show specific instructions for the current word"""
	var difficulty = get_word_difficulty(current_word)
	var needed_letters = get_unique_letters_in_word(current_word)
	var available_letters_list = []
	
	for bottle in bottle_letters:
		available_letters_list.append(bottle_letters[bottle].to_upper())
	
	print("=== HOW TO SPELL '", current_word.to_upper(), "' (", difficulty, ") ===")
	print("Letters needed: ", needed_letters)
	print("Available bottles: ", available_letters_list)
	print("🎯 CHALLENGE: Find the right letters from the mixed bottles!")
	print("1. Listen to the word carefully")
	print("2. Look at the available bottle letters")
	print("3. Drag letters in the correct order to spell the word")
	print("4. Some bottles have letters you DON'T need - choose wisely!")
	print("==========================================")

func get_word_difficulty(word: String) -> String:
	"""Get difficulty level based on word length"""
	match word.length():
		2:
			return "EASY (2 letters)"
		3:
			return "MEDIUM (3 letters)"
		4:
			return "HARD (4 letters)"
		_:
			return "UNKNOWN"

# Drag and Drop System
func _on_bottle_input_event(viewport, event, shape_idx, bottle):
	"""Handle bottle drag events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_dragging(bottle, event.global_position)
			else:
				stop_dragging(event.global_position)

func start_dragging(bottle, mouse_pos):
	"""Start dragging a bottle"""
	dragging_bottle = bottle
	drag_offset = bottle.global_position - mouse_pos
	print("Started dragging: ", get_bottle_letter(bottle).to_upper())

func stop_dragging(mouse_pos):
	"""Stop dragging and check for drop"""
	if dragging_bottle:
		var drop_position = mouse_pos + drag_offset
		
		if is_in_mixing_area(drop_position):
			handle_bottle_drop(dragging_bottle)
		else:
			# Return to original position
			if dragging_bottle in original_positions:
				dragging_bottle.global_position = original_positions[dragging_bottle]
		
		dragging_bottle = null

func _input(event):
	"""Handle mouse movement for dragging and keyboard shortcuts"""
	if event is InputEventMouseMotion and dragging_bottle:
		dragging_bottle.global_position = event.global_position + drag_offset
	
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reset_current_word()
		elif event.keycode == KEY_S:
			skip_current_word()
		elif event.keycode == KEY_P:
			_on_play_word_button_pressed()

func is_in_mixing_area(pos):
	"""Check if position is in mixing area"""
	if mixing_area:
		var mixing_rect = mixing_area.get_global_rect()
		return mixing_rect.has_point(pos)
	return false

func handle_bottle_drop(bottle):
	"""Handle bottle being dropped in mixing area"""
	var letter = get_bottle_letter(bottle)
	player_spelling += letter
	update_spelling_display()
	
	print("Added letter: ", letter.to_upper())
	print("Current spelling: ", player_spelling.to_upper())
	print("Target word: ", current_word.to_upper())
	
	# Return bottle to original position (allows reuse)
	if bottle in original_positions:
		bottle.global_position = original_positions[bottle]
	
	# Check if word is complete
	if player_spelling.length() >= current_word.length():
		check_word_completion()
	
	# Add a small delay to prevent accidental multiple drops
	await get_tree().create_timer(0.2).timeout

func get_bottle_letter(bottle):
	"""Get the letter for a bottle"""
	if bottle in bottle_letters:
		return bottle_letters[bottle]
	return ""

func update_spelling_display():
	"""Update the spelling display"""
	if spelling_display:
		# Show spelling with spaces between letters
		var display_text = ""
		for i in range(player_spelling.length()):
			if i > 0:
				display_text += " "
			display_text += player_spelling[i].to_upper()
		
		spelling_display.text = display_text
		print("Spelling progress: ", player_spelling.length(), "/", current_word.length(), " - ", player_spelling.to_upper())

func reset_current_word():
	"""Reset the current word spelling"""
	player_spelling = ""
	update_spelling_display()
	clear_mixing_area()
	print("Reset spelling for word: ", current_word.to_upper())

func skip_current_word():
	"""Skip to next word"""
	print("Skipping word: ", current_word.to_upper())
	current_word_in_level += 1
	load_next_word_in_level()

func check_word_completion():
	"""Check if the spelled word is correct"""
	if player_spelling.to_lower() == current_word.to_lower():
		word_correct()
	else:
		word_incorrect()

func word_correct():
	"""Handle correct word"""
	print("Correct! Word: ", current_word.to_upper())
	
	# Award points based on difficulty
	var points = 0
	var difficulty_bonus = ""
	match current_word.length():
		2:
			points = 5  # Easy words
			difficulty_bonus = "+5"
		3:
			points = 10 # Medium words
			difficulty_bonus = "+10"
		4:
			points = 15 # Hard words
			difficulty_bonus = "+15"
	
	score += points
	update_score_display()
	
	if correct_sound and correct_sound.stream:
		correct_sound.play()
	
	if current_word_label:
		current_word_label.text = "Perfect Mix! (" + difficulty_bonus + " points)"
		current_word_label.modulate = Color.GREEN
	if spelling_display:
		spelling_display.modulate = Color.GREEN
	
	# Wait 2 seconds, then move to next word in level
	await get_tree().create_timer(2.0).timeout
	current_word_in_level += 1
	
	if current_word_label:
		current_word_label.modulate = Color.WHITE
	if spelling_display:
		spelling_display.modulate = Color.WHITE
	
	# Load next word in current level
	load_next_word_in_level()
	
	# Auto-play the next word after a short delay
	await get_tree().create_timer(1.0).timeout
	if has_words_in_current_level() and current_word_in_level < word_levels[current_level].size():
		auto_play_next_word()

func word_incorrect():
	"""Handle incorrect word"""
	print("Incorrect! Expected: ", current_word.to_upper(), " Got: ", player_spelling.to_upper())
	
	if wrong_sound and wrong_sound.stream:
		wrong_sound.play()
	
	if current_word_label:
		current_word_label.text = "Mix again!"
		current_word_label.modulate = Color.RED
	if spelling_display:
		spelling_display.modulate = Color.RED
	
	await get_tree().create_timer(2.0).timeout
	
	if current_word_label:
		current_word_label.modulate = Color.WHITE
		current_word_label.text = current_word.to_upper()
	if spelling_display:
		spelling_display.modulate = Color.WHITE
	
	player_spelling = ""
	update_spelling_display()
	clear_mixing_area()
	
	# Automatically show instructions again and replay word
	await get_tree().create_timer(0.5).timeout
	show_word_instructions()
	await get_tree().create_timer(1.0).timeout
	play_word_audio()
	
	print("🔄 Try mixing again! Listen and spell: ", current_word.to_upper())

func update_score_display():
	"""Update score display"""
	if score_label:
		score_label.text = "Score: " + str(score)

func _on_mixing_drop_zone_area_entered(area):
	"""Handle area entered in mixing zone"""
	if area in [bottle_a, bottle_e, bottle_t, bottle_c]:
		print("Bottle entered mixing zone: ", get_bottle_letter(area).to_upper())

# Navigation
func _on_back_button_pressed():
	"""Go back to main menu"""
	print("Going back to main menu")
	go_back_to_menu()

func _on_next_button_pressed():
	"""Go to next game"""
	print("Going to next game")
	go_to_next_game()

func go_back_to_menu():
	"""Navigate to main menu"""
	if background_music and background_music.playing:
		background_music.stop()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func go_to_next_game():
	"""Navigate to next game"""
	if background_music and background_music.playing:
		background_music.stop()
	
	if ResourceLoader.exists(NEXT_CUTSCENE):
		get_tree().change_scene_to_file(NEXT_CUTSCENE)
	else:
		print("Next game not available yet")
		go_back_to_menu()

func _exit_tree():
	"""Cleanup when exiting"""
	print("Leaving Making Words Game")

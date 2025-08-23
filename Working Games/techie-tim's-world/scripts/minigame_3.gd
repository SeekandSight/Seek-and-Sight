extends Control

# Node references
@onready var computer_screen = $MainContainer/GameContent/LeftPanel/ComputerScreen
@onready var system_status = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/SystemStatus
@onready var encrypted_password = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/EncryptedPassword
@onready var password_length = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/PasswordLength
@onready var audio_clue = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/CluesContainer/AudioClue
@onready var visual_clue = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/CluesContainer/VisualClue
@onready var letter_clue = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/CluesContainer/LetterClue
@onready var attempt_counter = $MainContainer/GameContent/LeftPanel/ComputerScreen/ScreenContent/AttemptCounter

# Right panel UI
@onready var level_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/LevelLabel
@onready var score_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/ScoreLabel
@onready var status_label = $MainContainer/GameContent/RightPanel/StatsPanel/StatsContainer/StatusLabel

# Password buttons
@onready var password1_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/PasswordOptions/Password1
@onready var password2_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/PasswordOptions/Password2
@onready var password3_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/PasswordOptions/Password3

# Control buttons
@onready var hint_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/HintButton
@onready var next_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/ControlButtons/NextPasswordButton
@onready var reset_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/ControlButtons/ResetButton
@onready var main_menu_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/ControlButtons/MainMenuButton
@onready var game_select_button = $MainContainer/GameContent/RightPanel/PasswordPanel/PasswordContainer/ControlButtons/GameSelectButton

# Game variables
var current_level = 1
var systems_unlocked = 0
var current_attempts = 0
var max_attempts = 3
var system_unlocked = false
var hints_used = 0

# Password database with multiple difficulty levels
var password_database = [
	# Level 1 - Easy 3-letter words
	{
		"correct": "CAT",
		"wrong_options": ["DOG", "BAT", "PIG", "HAT", "SUN"],
		"encrypted": "★ ● ■",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes 'meow' sound",
		"visual_clue": "👁️ VISUAL: Small furry pet with whiskers",
		"letter_clue": "🔤 PATTERN: Starts with 'C', rhymes with 'bat'",
		"extra_hint": "💡 BONUS: Has 9 lives and catches mice!"
	},
	{
		"correct": "DOG",
		"wrong_options": ["CAT", "PIG", "BAT", "HAT", "COW"],
		"encrypted": "◆ ○ ◇",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes 'woof' sound",
		"visual_clue": "👁️ VISUAL: Furry pet that wags its tail",
		"letter_clue": "🔤 PATTERN: Starts with 'D', man's best friend",
		"extra_hint": "💡 BONUS: Loves to fetch sticks and play!"
	},
	{
		"correct": "SUN",
		"wrong_options": ["MOON", "STAR", "SKY", "FIRE", "LAMP"],
		"encrypted": "☼ ◐ ☽",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes everything bright and warm",
		"visual_clue": "👁️ VISUAL: Yellow circle in the sky during day",
		"letter_clue": "🔤 PATTERN: Starts with 'S', rhymes with 'fun'",
		"extra_hint": "💡 BONUS: Plants need this to grow!"
	},
	# Level 2 - Medium 3-letter words
	{
		"correct": "BIG",
		"wrong_options": ["SMALL", "TINY", "HUGE", "WIDE", "TALL"],
		"encrypted": "◊ ▲ ♦",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Opposite of 'small'",
		"visual_clue": "👁️ VISUAL: Something very large in size",
		"letter_clue": "🔤 PATTERN: Starts with 'B', means huge",
		"extra_hint": "💡 BONUS: Elephants are this size!"
	},
	{
		"correct": "RED",
		"wrong_options": ["BLUE", "GREEN", "PINK", "GOLD", "GRAY"],
		"encrypted": "◈ ◉ ◈",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Color of fire and roses",
		"visual_clue": "👁️ VISUAL: Bright warm color",
		"letter_clue": "🔤 PATTERN: Starts with 'R', rhymes with 'bed'",
		"extra_hint": "💡 BONUS: Stop signs are this color!"
	},
	# Level 3 - Harder 3-letter words
	{
		"correct": "RUN",
		"wrong_options": ["WALK", "JUMP", "SKIP", "CRAWL", "FLY"],
		"encrypted": "※ ◈ ◐",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Moving very fast on feet",
		"visual_clue": "👁️ VISUAL: Quick movement, faster than walking",
		"letter_clue": "🔤 PATTERN: Starts with 'R', rhymes with 'fun'",
		"extra_hint": "💡 BONUS: What you do in a race!"
	},
	{
		"correct": "HAT",
		"wrong_options": ["CAP", "WIG", "BOW", "MASK", "BAND"],
		"encrypted": "▽ ◈ △",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Something you wear on your head",
		"visual_clue": "👁️ VISUAL: Clothing item that covers your head",
		"letter_clue": "🔤 PATTERN: Starts with 'H', rhymes with 'cat'",
		"extra_hint": "💡 BONUS: Keeps sun out of your eyes!"
	},
	# Level 4 - Advanced 3-letter words
	{
		"correct": "BED",
		"wrong_options": ["CHAIR", "TABLE", "DESK", "COUCH", "BENCH"],
		"encrypted": "◈ ◉ ▲",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Where you sleep at night",
		"visual_clue": "👁️ VISUAL: Soft furniture for sleeping",
		"letter_clue": "🔤 PATTERN: Starts with 'B', rhymes with 'red'",
		"extra_hint": "💡 BONUS: Has pillows and blankets!"
	},
	{
		"correct": "CAN",
		"wrong_options": ["BOX", "JAR", "BAG", "CUP", "BOWL"],
		"encrypted": "◎ ◈ ◐",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Metal container for food",
		"visual_clue": "👁️ VISUAL: Round metal container with label",
		"letter_clue": "🔤 PATTERN: Starts with 'C', able to do something",
		"extra_hint": "💡 BONUS: Soup often comes in this!"
	},
	# Level 5 - Expert 3-letter words
	{
		"correct": "TOP",
		"wrong_options": ["BOTTOM", "MIDDLE", "SIDE", "EDGE", "END"],
		"encrypted": "▲ ◈ ◐",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Highest part or best",
		"visual_clue": "👁️ VISUAL: The highest point of something",
		"letter_clue": "🔤 PATTERN: Starts with 'T', opposite of bottom",
		"extra_hint": "💡 BONUS: Peak of a mountain!"
	}
]

var password_buttons = []
var current_password_data
var randomized_options = []  # This will store the shuffled options
var correct_answer_index = -1  # Track where the correct answer is positioned
var locked_screen_style
var unlocked_screen_style

func _ready():
	print("🔐 Tim's Password Decoder - Starting!")
	
	# Initialize random seed with time-based seed for better randomization
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system()
	
	# Debug: Check if nodes are properly loaded
	print("Password buttons found: ", password1_button != null, password2_button != null, password3_button != null)
	print("Other UI elements: ", status_label != null, level_label != null)
	
	# Setup button array
	password_buttons = [password1_button, password2_button, password3_button]
	
	# Create screen styles
	setup_screen_styles()
	
	# Connect signals
	connect_signals()
	
	# Load first password
	load_current_password()
	
	# Initial UI update
	update_ui()
	
	print("Setup complete!")

func setup_screen_styles():
	# Locked screen style (red)
	locked_screen_style = StyleBoxFlat.new()
	locked_screen_style.bg_color = Color(0.1, 0.02, 0.02, 0.95)
	locked_screen_style.border_width_left = 6
	locked_screen_style.border_width_top = 6
	locked_screen_style.border_width_right = 6
	locked_screen_style.border_width_bottom = 6
	locked_screen_style.border_color = Color(1, 0.2, 0.2, 1)
	locked_screen_style.corner_radius_top_left = 25
	locked_screen_style.corner_radius_top_right = 25
	locked_screen_style.corner_radius_bottom_right = 25
	locked_screen_style.corner_radius_bottom_left = 25
	locked_screen_style.shadow_color = Color(1, 0.2, 0.2, 0.4)
	locked_screen_style.shadow_size = 10
	
	# Unlocked screen style (green)
	unlocked_screen_style = StyleBoxFlat.new()
	unlocked_screen_style.bg_color = Color(0.02, 0.1, 0.02, 0.95)
	unlocked_screen_style.border_width_left = 6
	unlocked_screen_style.border_width_top = 6
	unlocked_screen_style.border_width_right = 6
	unlocked_screen_style.border_width_bottom = 6
	unlocked_screen_style.border_color = Color(0.1, 1, 0.3, 1)
	unlocked_screen_style.corner_radius_top_left = 25
	unlocked_screen_style.corner_radius_top_right = 25
	unlocked_screen_style.corner_radius_bottom_right = 25
	unlocked_screen_style.corner_radius_bottom_left = 25
	unlocked_screen_style.shadow_color = Color(0.1, 1, 0.3, 0.4)
	unlocked_screen_style.shadow_size = 10

func connect_signals():
	# Make sure nodes exist before connecting
	if password1_button:
		password1_button.pressed.connect(_on_password_selected.bind(0))
		print("Connected password1_button")
	else:
		print("ERROR: password1_button is null!")
		
	if password2_button:
		password2_button.pressed.connect(_on_password_selected.bind(1))
		print("Connected password2_button")
	else:
		print("ERROR: password2_button is null!")
		
	if password3_button:
		password3_button.pressed.connect(_on_password_selected.bind(2))
		print("Connected password3_button")
	else:
		print("ERROR: password3_button is null!")
	
	# Control buttons
	if hint_button:
		hint_button.pressed.connect(_on_hint_button_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_password_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if game_select_button:
		game_select_button.pressed.connect(_on_game_select_pressed)

func generate_randomized_options(password_data: Dictionary) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system() + current_level * 1000  # Different seed per level
	
	var options = []
	
	# Add the correct answer
	options.append(password_data.correct)
	
	# Randomly select 2 wrong options from the available wrong options
	var wrong_options = password_data.wrong_options.duplicate()
	
	# Use custom shuffle with better randomization
	for i in range(wrong_options.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = wrong_options[i]
		wrong_options[i] = wrong_options[j]
		wrong_options[j] = temp
	
	# Take the first 2 wrong options
	for i in range(min(2, wrong_options.size())):
		options.append(wrong_options[i])
	
	# Custom shuffle for final options with multiple iterations for better randomization
	for iteration in range(5):  # Multiple shuffle passes
		for i in range(options.size() - 1, 0, -1):
			var j = rng.randi() % (i + 1)
			var temp = options[i]
			options[i] = options[j]
			options[j] = temp
	
	# Find where the correct answer ended up
	correct_answer_index = options.find(password_data.correct)
	
	print("Generated options: ", options)
	print("Correct answer '", password_data.correct, "' is at index: ", correct_answer_index)
	print("Random seed used: ", rng.seed)
	
	return options

func load_current_password():
	if current_level > password_database.size():
		show_completion()
		return
	
	current_password_data = password_database[current_level - 1]
	current_attempts = 0
	hints_used = 0
	system_unlocked = false
	
	# Generate randomized options for this level
	randomized_options = generate_randomized_options(current_password_data)
	
	# Update encrypted display
	encrypted_password.text = current_password_data.encrypted
	password_length.text = "PASSWORD LENGTH: " + str(current_password_data.length) + " CHARACTERS"
	
	# Update clues
	audio_clue.text = current_password_data.audio_clue
	visual_clue.text = current_password_data.visual_clue
	letter_clue.text = current_password_data.letter_clue
	
	# Update password buttons with randomized options
	for i in range(password_buttons.size()):
		if i < randomized_options.size():
			var option = randomized_options[i]
			password_buttons[i].text = get_emoji_for_word(option) + " " + option
			password_buttons[i].visible = true
			password_buttons[i].disabled = false
			password_buttons[i].modulate = Color(1, 1, 1, 1)
		else:
			password_buttons[i].visible = false
	
	# Reset screen to locked state
	computer_screen.add_theme_stylebox_override("panel", locked_screen_style)
	system_status.text = "🔒 SYSTEM LOCKED"
	system_status.modulate = Color(1, 0.3, 0.3, 1)
	
	update_ui()

func get_emoji_for_word(word: String) -> String:
	match word.to_upper():
		"CAT": return "🐱"
		"DOG": return "🐶"
		"BAT": return "🦇"
		"PIG": return "🐷"
		"SUN": return "☀️"
		"MOON": return "🌙"
		"STAR": return "⭐"
		"BIG": return "📏"
		"SMALL": return "🔍"
		"TINY": return "🤏"
		"RED": return "🔴"
		"BLUE": return "🔵"
		"GREEN": return "🟢"
		"RUN": return "🏃"
		"WALK": return "🚶"
		"JUMP": return "🦘"
		"HAT": return "👒"
		"CAP": return "🧢"
		"WIG": return "💇"
		"BED": return "🛏️"
		"CHAIR": return "🪑"
		"TABLE": return "🪑"
		"CAN": return "🥫"
		"BOX": return "📦"
		"JAR": return "🫙"
		"TOP": return "🔝"
		"BOTTOM": return "⬇️"
		"MIDDLE": return "🎯"
		"SKIP": return "⏭️"
		"CRAWL": return "🐛"
		"FLY": return "🪰"
		"COW": return "🐄"
		"SKY": return "🌌"
		"FIRE": return "🔥"
		"LAMP": return "💡"
		"HUGE": return "🦣"
		"WIDE": return "↔️"
		"TALL": return "📏"
		"PINK": return "🌸"
		"GOLD": return "🥇"
		"GRAY": return "🌫️"
		"DESK": return "🖥️"
		"COUCH": return "🛋️"
		"BENCH": return "🪑"
		"BAG": return "👜"
		"CUP": return "☕"
		"BOWL": return "🍜"
		"SIDE": return "↔️"
		"EDGE": return "🔪"
		"END": return "🏁"
		"BOW": return "🎀"
		"MASK": return "🎭"
		"BAND": return "🎵"
		_: return "❓"

func _on_password_selected(option_index: int):
	print("Password selected: ", option_index)
	
	if system_unlocked:
		status_label.text = "System already unlocked! Move to next password."
		return
	
	if current_attempts >= max_attempts:
		status_label.text = "Maximum attempts reached! Reset system to try again."
		return
	
	current_attempts += 1
	var selected_word = randomized_options[option_index]
	
	print("Selected word: ", selected_word, " | Correct: ", current_password_data.correct)
	print("Selected index: ", option_index, " | Correct index: ", correct_answer_index)
	
	# Check if the selected option is the correct answer
	if option_index == correct_answer_index:
		unlock_system()
	else:
		show_wrong_password(option_index)

func unlock_system():
	system_unlocked = true
	systems_unlocked += 1
	
	# Change screen to unlocked (green)
	computer_screen.add_theme_stylebox_override("panel", unlocked_screen_style)
	system_status.text = "🔓 ACCESS GRANTED"
	system_status.modulate = Color(0.3, 1, 0.3, 1)
	encrypted_password.text = current_password_data.correct
	encrypted_password.modulate = Color(0.3, 1, 0.3, 1)
	
	# Celebration animation
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(system_status, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(system_status, "scale", Vector2(1.0, 1.0), 0.3)
	
	status_label.text = "🎉 PASSWORD DECODED! System unlocked! 🎉"
	
	# Disable password buttons and highlight correct answer
	for i in range(password_buttons.size()):
		password_buttons[i].disabled = true
		if i == correct_answer_index:
			password_buttons[i].modulate = Color(0.3, 1, 0.3, 1)  # Highlight correct answer
		else:
			password_buttons[i].modulate = Color(0.7, 0.7, 0.7, 1)  # Dim wrong answers
	
	# Auto-advance after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if current_level < password_database.size():
		_on_next_password_pressed()
	else:
		show_completion()

func show_wrong_password(wrong_index: int):
	# Flash the wrong button red
	password_buttons[wrong_index].modulate = Color(1, 0.3, 0.3, 1)
	
	var remaining_attempts = max_attempts - current_attempts
	if remaining_attempts > 0:
		status_label.text = "❌ Wrong password! " + str(remaining_attempts) + " attempts remaining."
		
		# Reset button color after flash
		await get_tree().create_timer(1.0).timeout
		password_buttons[wrong_index].modulate = Color(1, 1, 1, 1)
	else:
		status_label.text = "🚫 LOCKOUT! Maximum attempts reached. Reset to try again."
		
		# Disable all buttons and highlight the correct answer
		for i in range(password_buttons.size()):
			password_buttons[i].disabled = true
			if i == correct_answer_index:
				password_buttons[i].modulate = Color(0.3, 1, 0.3, 1)  # Show correct answer
			else:
				password_buttons[i].modulate = Color(0.5, 0.5, 0.5, 1)  # Dim others
	
	update_ui()

func _on_hint_button_pressed():
	if hints_used >= 1:
		status_label.text = "Only one extra hint per password!"
		return
	
	hints_used += 1
	
	# Show extra hint temporarily
	var original_text = letter_clue.text
	letter_clue.text = current_password_data.extra_hint
	letter_clue.modulate = Color(1, 1, 0.4, 1)  # Yellow highlight
	
	status_label.text = "💡 Extra hint revealed! Use it wisely."
	
	# Restore original clue after 5 seconds
	await get_tree().create_timer(5.0).timeout
	letter_clue.text = original_text
	letter_clue.modulate = Color(0.4, 0.8, 1, 1)

func _on_next_password_pressed():
	if not system_unlocked:
		status_label.text = "Unlock current system first!"
		return
	
	current_level += 1
	load_current_password()

func _on_reset_pressed():
	# Reset current password attempt
	current_attempts = 0
	hints_used = 0
	system_unlocked = false
	
	# DON'T regenerate options - keep the same randomized positions
	# Just re-enable the existing buttons with the same options
	for i in range(password_buttons.size()):
		if i < randomized_options.size():
			password_buttons[i].disabled = false
			password_buttons[i].modulate = Color(1, 1, 1, 1)
		else:
			password_buttons[i].visible = false
	
	# Reset screen to locked
	computer_screen.add_theme_stylebox_override("panel", locked_screen_style)
	system_status.text = "🔒 SYSTEM LOCKED"
	system_status.modulate = Color(1, 0.3, 0.3, 1)
	encrypted_password.text = current_password_data.encrypted
	encrypted_password.modulate = Color(0.9, 0.9, 0.9, 1)
	
	# Reset clue color
	letter_clue.modulate = Color(0.4, 0.8, 1, 1)
	
	update_ui()
	status_label.text = "System reset! Same passwords, try again."

func show_completion():
	status_label.text = "🏆 ALL SYSTEMS UNLOCKED! Master decoder! 🏆"
	system_status.text = "🏆 MISSION COMPLETE"
	system_status.modulate = Color.GOLD
	encrypted_password.text = "MASTER HACKER!"
	encrypted_password.modulate = Color.GOLD
	
	# Disable all buttons
	for button in password_buttons:
		button.visible = false

func update_ui():
	level_label.text = "SECURITY LEVEL: " + str(current_level)
	score_label.text = "SYSTEMS UNLOCKED: " + str(systems_unlocked)
	attempt_counter.text = "DECRYPTION ATTEMPTS: " + str(current_attempts) + "/" + str(max_attempts)
	
	if system_unlocked:
		status_label.text = "✅ System unlocked! Ready for next challenge."
	elif current_attempts >= max_attempts:
		status_label.text = "🚫 Locked out! Reset to try again."
	else:
		status_label.text = "🔍 Analyze the clues and select the correct password!"

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

# Keyboard input for accessibility
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				var option_index = event.keycode - KEY_1
				if option_index < password_buttons.size() and password_buttons[option_index].visible:
					_on_password_selected(option_index)
			KEY_H:
				_on_hint_button_pressed()
			KEY_N:
				_on_next_password_pressed()
			KEY_R:
				_on_reset_pressed()
			KEY_SPACE, KEY_ENTER:
				# Quick access to first visible password option
				if password_buttons[0].visible and not password_buttons[0].disabled:
					_on_password_selected(0)

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
	{
		"correct": "CAT",
		"wrong_options": ["DOG", "BAT", "PIG", "HAT", "SUN"],
		"encrypted": "★ ● ■ ",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes 'meow' sound",
		"visual_clue": "👁️ VISUAL: Small furry pet with whiskers",
		"letter_clue": "🔤 PATTERN: Starts with 'C', rhymes with 'bat'",
		"extra_hint": "💡 BONUS: Has 9 lives and catches mice!"
	},
	{
		"correct": "DOG",
		"wrong_options": ["CAT", "PIG", "BAT", "HAT", "COW"],
		"encrypted": "◆ ◯ ◇",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes 'woof' sound",
		"visual_clue": "👁️ VISUAL: Furry pet that wags its tail",
		"letter_clue": "🔤 PATTERN: Starts with 'D', man's best friend",
		"extra_hint": "💡 BONUS: Loves to fetch sticks and play!"
	},
	{
		"correct": "SUN",
		"wrong_options": ["MOON", "STAR", "SKY", "FIRE", "LAMP"],
		"encrypted": "☼ ● ☽",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Makes everything bright and warm",
		"visual_clue": "👁️ VISUAL: Yellow circle in the sky during day",
		"letter_clue": "🔤 PATTERN: Starts with 'S', rhymes with 'fun'",
		"extra_hint": "💡 BONUS: Plants need this to grow!"
	},
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
	{
		"correct": "RUN",
		"wrong_options": ["WALK", "JUMP", "SKIP", "CRAWL", "FLY"],
		"encrypted": "※ ◈ ●",
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
		"encrypted": "◎ ◈ ●",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Metal container for food",
		"visual_clue": "👁️ VISUAL: Round metal container with label",
		"letter_clue": "🔤 PATTERN: Starts with 'C', able to do something",
		"extra_hint": "💡 BONUS: Soup often comes in this!"
	},
	{
		"correct": "TOP",
		"wrong_options": ["BOTTOM", "MIDDLE", "SIDE", "EDGE", "END"],
		"encrypted": "▲ ◈ ●",
		"length": 3,
		"audio_clue": "🔊 AUDIO: Highest part or best",
		"visual_clue": "👁️ VISUAL: The highest point of something",
		"letter_clue": "🔤 PATTERN: Starts with 'T', opposite of bottom",
		"extra_hint": "💡 BONUS: Peak of a mountain!"
	}
]

var password_buttons = []
var current_password_data
var randomized_options = []
var correct_answer_index = -1
var locked_screen_style
var unlocked_screen_style

func _ready():
	print("🔍 Tim's Password Decoder - Starting!")
	
	password_buttons = [password1_button, password2_button, password3_button]
	
	setup_screen_styles()
	connect_signals()
	load_current_password()
	update_ui()

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
	password1_button.pressed.connect(_on_password_selected.bind(0))
	password2_button.pressed.connect(_on_password_selected.bind(1))
	password3_button.pressed.connect(_on_password_selected.bind(2))
	
	hint_button.pressed.connect(_on_hint_button_pressed)
	next_button.pressed.connect(_on_next_password_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	game_select_button.pressed.connect(_on_game_select_pressed)

func generate_randomized_options(password_data: Dictionary) -> Array:
	var options = []
	options.append(password_data.correct)
	
	var wrong_options = password_data.wrong_options.duplicate()
	wrong_options.shuffle()
	
	for i in range(min(2, wrong_options.size())):
		options.append(wrong_options[i])
	
	options.shuffle()
	correct_answer_index = options.find(password_data.correct)
	
	return options

func load_current_password():
	if current_level > password_database.size():
		show_completion()
		return
	
	current_password_data = password_database[current_level - 1]
	current_attempts = 0
	hints_used = 0
	system_unlocked = false
	
	randomized_options = generate_randomized_options(current_password_data)
	
	encrypted_password.text = current_password_data.encrypted
	password_length.text = "Password length: " + str(current_password_data.length) + " characters"
	
	audio_clue.text = current_password_data.audio_clue
	visual_clue.text = current_password_data.visual_clue
	letter_clue.text = current_password_data.letter_clue
	
	for i in range(password_buttons.size()):
		if i < randomized_options.size():
			var option = randomized_options[i]
			password_buttons[i].text = get_emoji_for_word(option) + " " + option
			password_buttons[i].visible = true
			password_buttons[i].disabled = false
			password_buttons[i].modulate = Color(1, 1, 1, 1)
		else:
			password_buttons[i].visible = false
	
	computer_screen.add_theme_stylebox_override("panel", locked_screen_style)
	system_status.text = "🔒 System Locked"
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
		"BIG": return "🔍"
		"SMALL": return "🔎"
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
		"SKIP": return "⭐"
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
		"END": return "🔚"
		"BOW": return "🎀"
		"MASK": return "🎭"
		"BAND": return "🎵"
		_: return "❓"

func _on_password_selected(option_index: int):
	if system_unlocked or current_attempts >= max_attempts:
		return
	
	current_attempts += 1
	
	if option_index == correct_answer_index:
		unlock_system()
	else:
		show_wrong_password(option_index)

func unlock_system():
	system_unlocked = true
	systems_unlocked += 1
	
	computer_screen.add_theme_stylebox_override("panel", unlocked_screen_style)
	system_status.text = "🔓 Access Granted"
	system_status.modulate = Color(0.3, 1, 0.3, 1)
	encrypted_password.text = current_password_data.correct
	encrypted_password.modulate = Color(0.3, 1, 0.3, 1)
	
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(system_status, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(system_status, "scale", Vector2(1.0, 1.0), 0.3)
	
	status_label.text = "🎉 Password decoded! System unlocked! Click 'Next Password' to continue. 🎉"
	
	for i in range(password_buttons.size()):
		password_buttons[i].disabled = true
		if i == correct_answer_index:
			password_buttons[i].modulate = Color(0.3, 1, 0.3, 1)
		else:
			password_buttons[i].modulate = Color(0.7, 0.7, 0.7, 1)

func show_wrong_password(wrong_index: int):
	password_buttons[wrong_index].modulate = Color(1, 0.3, 0.3, 1)
	
	var remaining_attempts = max_attempts - current_attempts
	if remaining_attempts > 0:
		status_label.text = "❌ Wrong password! " + str(remaining_attempts) + " attempts remaining."
		
		await get_tree().create_timer(1.0).timeout
		password_buttons[wrong_index].modulate = Color(1, 1, 1, 1)
	else:
		status_label.text = "🚫 Lockout! Maximum attempts reached. Reset to try again."
		
		for i in range(password_buttons.size()):
			password_buttons[i].disabled = true
			if i == correct_answer_index:
				password_buttons[i].modulate = Color(0.3, 1, 0.3, 1)
			else:
				password_buttons[i].modulate = Color(0.5, 0.5, 0.5, 1)
	
	update_ui()

func _on_hint_button_pressed():
	if hints_used >= 1:
		status_label.text = "Only one extra hint per password!"
		return
	
	hints_used += 1
	
	var original_text = letter_clue.text
	letter_clue.text = current_password_data.extra_hint
	letter_clue.modulate = Color(1, 1, 0.4, 1)
	
	status_label.text = "💡 Extra hint revealed! Use it wisely."
	
	await get_tree().create_timer(5.0).timeout
	letter_clue.text = original_text
	letter_clue.modulate = Color(0.4, 0.8, 1, 1)

func _on_next_password_pressed():
	# Check if this is "PLAY AGAIN" from completion screen
	if next_button.text == "🔄 PLAY AGAIN":
		restart_game()
		return
	
	if not system_unlocked:
		status_label.text = "Unlock current system first!"
		return
	
	if current_level >= password_database.size():
		show_completion()
		return
	
	current_level += 1
	load_current_password()

func restart_game():
	# Reset all game variables to starting state
	current_level = 1
	systems_unlocked = 0
	current_attempts = 0
	hints_used = 0
	system_unlocked = false
	
	# Reset button texts back to normal
	next_button.text = "⭐ NEXT PASSWORD"
	main_menu_button.text = "🏠 MAIN TERMINAL"
	game_select_button.text = "🎮 GAME SELECT"
	reset_button.visible = true
	
	# Load first level
	load_current_password()
	
	status_label.text = "Game restarted! Ready to decode passwords from the beginning."

func _on_reset_pressed():
	# Check if this is a "Play Again" reset from completion screen
	if current_level > password_database.size():
		# Reset entire game to start over
		current_level = 1
		systems_unlocked = 0
		reset_button.text = "🔄 RESET SYSTEM"  # Change button text back
	
	# Reset current level state
	current_attempts = 0
	hints_used = 0
	system_unlocked = false
	
	# Load the current password (or first password if restarting)
	load_current_password()
	
	# Reset all UI elements to starting state
	for i in range(password_buttons.size()):
		if i < randomized_options.size():
			password_buttons[i].disabled = false
			password_buttons[i].modulate = Color(1, 1, 1, 1)
			password_buttons[i].visible = true
		else:
			password_buttons[i].visible = false
	
	computer_screen.add_theme_stylebox_override("panel", locked_screen_style)
	system_status.text = "🔒 System Locked"
	system_status.modulate = Color(1, 0.3, 0.3, 1)
	encrypted_password.text = current_password_data.encrypted
	encrypted_password.modulate = Color(0.9, 0.9, 0.9, 1)
	
	letter_clue.modulate = Color(0.4, 0.8, 1, 1)
	
	update_ui()
	
	if current_level == 1 and systems_unlocked == 0:
		status_label.text = "Game restarted! Ready to play again from the beginning."
	else:
		status_label.text = "System reset! Same passwords, try again."

func show_completion():
	status_label.text = "🏆 All systems unlocked! Master decoder! 🏆"
	system_status.text = "🏆 Mission Complete"
	system_status.modulate = Color.GOLD
	encrypted_password.text = "Master Hacker!"
	encrypted_password.modulate = Color.GOLD
	
	# Hide password buttons
	for button in password_buttons:
		button.visible = false
	
	# Change control buttons to completion options
	next_button.text = "🔄 Play Again"
	next_button.visible = true
	main_menu_button.text = "🏠 Main Menu"
	main_menu_button.visible = true
	game_select_button.text = "🎮 Game Select"
	game_select_button.visible = true
	reset_button.visible = false  # Hide reset button at completion

func update_ui():
	level_label.text = "Security Level: " + str(current_level)
	score_label.text = "Systems Unlocked: " + str(systems_unlocked)
	attempt_counter.text = "Decryption Attempts: " + str(current_attempts) + "/" + str(max_attempts)
	
	if system_unlocked:
		status_label.text = "✅ System unlocked! Click 'Next Password' to continue."
	elif current_attempts >= max_attempts:
		status_label.text = "🚫 Locked out! Reset to try again."
	else:
		status_label.text = "🔍 Analyze the clues and select the correct password!"

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_game_select_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")

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

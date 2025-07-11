extends Node2D

# Making Words Cutscene Script with Typewriter Effect
# This introduces the player to the potion mixing game

# Scene paths
const MAKING_WORDS_GAME_SCENE = "res://scenes/Scene2_MakingWordsGame.tscn"
const MAIN_MENU_SCENE = "res://scenes/Scene1_ScienceMainMenu.tscn"

# Dialogue lines with timing
var dialogue_lines = [
	"Welcome to my laboratory!",
	"Here we mix magical potions...",
	"to create sight words!",
	"Listen carefully to each word,",
	"then drag the right potion bottles",
	"to spell it out!",
	"Are you ready to start mixing?"
]

var current_line = 0
var current_char = 0
var typewriter_speed = 0.05  # Speed of typing effect
var is_typing = false
var skip_pressed = false

# UI references
@onready var dialogue_text = $UI/SpeechBubble/DialogueText
@onready var continue_button = $UI/ContinueButton
@onready var skip_button = $UI/SkipButton
@onready var intro_audio = $Audio/IntroAudio
@onready var background_music = $Audio/BackgroundMusic
@onready var timer = $Timer

func _ready():
	print("Making Words Cutscene Loaded")
	setup_cutscene()

func _on_tree_entered():
	# Start the cutscene sequence
	start_cutscene()

func setup_cutscene():
	# Initialize UI
	dialogue_text.text = ""
	continue_button.visible = false
	skip_button.visible = true

func start_cutscene():
	# Play intro audio and start dialogue
	#if intro_audio.stream:
		#intro_audio.play()
	
	# Start typewriter effect
	await get_tree().create_timer(0.5).timeout  # Small delay
	start_typing_dialogue()

func start_typing_dialogue():
	if current_line < dialogue_lines.size():
		current_char = 0
		is_typing = true
		dialogue_text.text = ""
		type_next_character()
	else:
		# All dialogue finished
		show_continue_button()

func type_next_character():
	if skip_pressed:
		# Show full text immediately
		dialogue_text.text = dialogue_lines[current_line]
		is_typing = false
		await get_tree().create_timer(1.0).timeout
		next_line()
		return
	
	if current_char < dialogue_lines[current_line].length():
		# Add next character
		dialogue_text.text += dialogue_lines[current_line][current_char]
		current_char += 1
		
		# Continue typing
		timer.wait_time = typewriter_speed
		timer.start()
	else:
		# Line finished
		is_typing = false
		await get_tree().create_timer(1.5).timeout  # Pause between lines
		next_line()

func _on_timer_timeout():
	if is_typing:
		type_next_character()

func next_line():
	current_line += 1
	if current_line < dialogue_lines.size():
		start_typing_dialogue()
	else:
		show_continue_button()

func show_continue_button():
	skip_button.visible = false
	continue_button.visible = true
	dialogue_text.text = "Ready to start mixing potions?"

# Button handlers
func _on_skip_button_pressed():
	print("Skip button pressed")
	skip_pressed = true
	if is_typing:
		# Complete current line immediately
		dialogue_text.text = dialogue_lines[current_line]
		is_typing = false
	else:
		# Skip to end
		current_line = dialogue_lines.size()
		show_continue_button()

func _on_continue_button_pressed():
	print("Continue to Making Words Game")
	go_to_making_words_game()

func _on_intro_audio_finished():
	print("Intro audio finished")
	# Audio finished, can proceed faster if needed

# Scene transitions
func go_to_making_words_game():
	# Stop audio
	if background_music.playing:
		background_music.stop()
	if intro_audio.playing:
		intro_audio.stop()
	
	# Change to the actual game scene
	if ResourceLoader.exists(MAKING_WORDS_GAME_SCENE):
		get_tree().change_scene_to_file(MAKING_WORDS_GAME_SCENE)
	else:
		print("Making Words Game scene not found: ", MAKING_WORDS_GAME_SCENE)
		show_debug_message("Making Words Game scene coming soon!")

func go_back_to_menu():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# Debug helper
func show_debug_message(message: String):
	print("DEBUG: ", message)
	dialogue_text.text = message
	continue_button.text = "Back to Menu"
	continue_button.pressed.connect(go_back_to_menu)

# Handle input for skipping
func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if continue_button.visible:
			_on_continue_button_pressed()
		else:
			_on_skip_button_pressed()

# Cleanup
func _exit_tree():
	print("Leaving Making Words Cutscene")

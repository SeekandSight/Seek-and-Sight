extends Node2D

# Making Words Cutscene Script with Typewriter Effect
# This introduces the player to the potion mixing game

# Scene paths - CORRECTED BACK NAVIGATION
const MAKING_WORDS_GAME_SCENE = "res://scenes/Scene2_MakingWordsGame.tscn"
const MAIN_MENU_SCENE = "res://scenes/Scene1_ScienceMainMenu.tscn"  # Back goes to main menu (first cutscene)

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
@onready var back_button = $UI/BackButton
@onready var intro_audio = $Audio/IntroAudio
@onready var background_music = $Audio/BackgroundMusic
@onready var timer = $Timer

func _ready():
	print("Making Words Cutscene Loaded")
	setup_cutscene()

func _on_tree_entered():
	start_cutscene()

func setup_cutscene():
	dialogue_text.text = ""
	continue_button.visible = false
	skip_button.visible = true
	back_button.visible = true

func start_cutscene():
	await get_tree().create_timer(0.5).timeout
	start_typing_dialogue()

func start_typing_dialogue():
	if current_line < dialogue_lines.size():
		current_char = 0
		is_typing = true
		dialogue_text.text = ""
		type_next_character()
	else:
		show_continue_button()

func type_next_character():
	if skip_pressed:
		dialogue_text.text = dialogue_lines[current_line]
		is_typing = false
		await get_tree().create_timer(1.0).timeout
		next_line()
		return
	
	if current_char < dialogue_lines[current_line].length():
		dialogue_text.text += dialogue_lines[current_line][current_char]
		current_char += 1
		timer.wait_time = typewriter_speed
		timer.start()
	else:
		is_typing = false
		await get_tree().create_timer(1.5).timeout
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

# CORRECTED: Back goes to Main Menu (this is the first cutscene)
func _on_back_button_pressed():
	"""Go back to main menu"""
	print("Going back to main menu from Making Words cutscene")
	
	if background_music and background_music.playing:
		background_music.stop()
	if intro_audio and intro_audio.playing:
		intro_audio.stop()
	
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_skip_button_pressed():
	print("Skip button pressed")
	skip_pressed = true
	if is_typing:
		dialogue_text.text = dialogue_lines[current_line]
		is_typing = false
	else:
		current_line = dialogue_lines.size()
		show_continue_button()

func _on_continue_button_pressed():
	print("Continue to Making Words Game")
	go_to_making_words_game()

func _on_intro_audio_finished():
	print("Intro audio finished")

func go_to_making_words_game():
	if background_music and background_music.playing:
		background_music.stop()
	if intro_audio and intro_audio.playing:
		intro_audio.stop()
	
	if ResourceLoader.exists(MAKING_WORDS_GAME_SCENE):
		get_tree().change_scene_to_file(MAKING_WORDS_GAME_SCENE)
	else:
		print("Making Words Game scene not found: ", MAKING_WORDS_GAME_SCENE)
		show_debug_message("Making Words Game scene coming soon!")

func go_back_to_menu():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func show_debug_message(message: String):
	print("DEBUG: ", message)
	dialogue_text.text = message
	continue_button.text = "Back to Menu"
	continue_button.pressed.connect(go_back_to_menu)

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if continue_button.visible:
			_on_continue_button_pressed()
		else:
			_on_skip_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func _exit_tree():
	print("Leaving Making Words Cutscene")

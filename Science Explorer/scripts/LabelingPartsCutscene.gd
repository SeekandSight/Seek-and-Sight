<<<<<<< HEAD
# LabelingPartsCutscene.gd
extends Control

# Scene paths - CORRECTED BACK NAVIGATION
const MAKING_WORDS_GAME = "res://scenes/Scene2_MakingWordsGame.tscn"  # Back goes to previous game
const LABELING_PARTS_GAME = "res://scenes/Scene3_LabelingPartsGame.tscn"

@onready var speech_text = $SpeechBubble/SpeechText
@onready var continue_button = $ContinueButton
@onready var back_button = $BackButton
@onready var audio_player = $AudioStreamPlayer
@onready var background_music = $BackgroundMusic

var dialogue_steps = [
	"Hi there! I'm Sandy, and I love studying plants!",
	"Today we're going to learn about the different parts of a plant.",
	"Plants have roots, stems, leaves, and flowers - each with important jobs!",
	"Let's practice labeling these parts together. Are you ready?"
]

var current_step = 0

func _ready():
	print("=== LABELING PARTS CUTSCENE ===")
	print("Speech text: ", speech_text)
	print("Continue button: ", continue_button)
	print("Back button: ", back_button)
	
	# Start with the first dialogue
	show_current_dialogue()
	
	# Start background music if available
	if background_music:
		background_music.volume_db = -25
		background_music.play()

func show_current_dialogue():
	if current_step < dialogue_steps.size():
		speech_text.text = dialogue_steps[current_step]
		
		# Change button text based on step
		if current_step == dialogue_steps.size() - 1:
			continue_button.text = "Let's Start!"
		else:
			continue_button.text = "Continue"

func _on_continue_button_pressed():
	print("Continue button pressed, step: ", current_step)
	
	# Play click sound if available
	if audio_player:
		audio_player.play()
	
	current_step += 1
	
	if current_step < dialogue_steps.size():
		# Show next dialogue
		show_current_dialogue()
	else:
		# Go to the labeling parts game
		start_labeling_game()

# CORRECTED: Back goes to Making Words Game (previous scene in sequence)
func _on_back_button_pressed():
	"""Go back to Making Words Game"""
	print("Going back to Making Words Game from Labeling Parts cutscene")
	
	# Stop background music if playing
	if background_music and background_music.playing:
		background_music.stop()
	
	# Change to previous game
	get_tree().change_scene_to_file(MAKING_WORDS_GAME)

func start_labeling_game():
	"""Start the labeling parts game"""
	print("Starting Labeling Parts game")
	
	# Stop background music
	if background_music and background_music.playing:
		background_music.stop()
	
	# Go to labeling parts game
	if ResourceLoader.exists(LABELING_PARTS_GAME):
		get_tree().change_scene_to_file(LABELING_PARTS_GAME)
	else:
		print("Labeling Parts Game scene not found, going back to Making Words")
		get_tree().change_scene_to_file(MAKING_WORDS_GAME)

func _input(event):
	"""Handle input"""
	if event.is_action_pressed("ui_accept"):
		_on_continue_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
=======
extends Control

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Scene3_LabelingPartsGame.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Scene1_ScienceMainMenu.tscn")
>>>>>>> d82c90b2235a0ebab599504baf2006a1387f1547

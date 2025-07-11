# LabelingPartsCutscene.gd
extends Control

@onready var speech_text = $SpeechBubble/SpeechText
@onready var continue_button = $ContinueButton
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
	# Play click sound if available
	if audio_player:
		audio_player.play()
	
	current_step += 1
	
	if current_step < dialogue_steps.size():
		# Show next dialogue
		show_current_dialogue()
	else:
		# Go to the labeling parts game
		get_tree().change_scene_to_file("res://scenes/Scene3_LabelingPartsGame.tscn")

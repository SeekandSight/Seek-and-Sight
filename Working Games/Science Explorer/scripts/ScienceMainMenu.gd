# ScienceMainMenu.gd
extends Node2D

# Scene paths for cutscenes - CORRECTED for proper flow
const MAKING_WORDS_CUTSCENE = "res://scenes/Scene2_MakingWordsCutscene.tscn"
const LABELING_PARTS_CUTSCENE = "res://scenes/Scene3_LabelingPartsCutscene.tscn"
const FINDING_WORDS_CUTSCENE = "res://scenes/Scene6_FindingWordsCutscene.tscn"

@onready var welcome_audio = $Audio/WelcomeAudio
@onready var background_music = $Audio/BackgroundMusic
@onready var play_button = $UI/MenuButtons/PlayButton

func _ready():
	print("Science Main Menu Loaded")
	setup_menu()

func _on_tree_entered():
	print("Main Menu Scene Entered")

func setup_menu():
	# Start background music if available
	if background_music:
		background_music.volume_db = -20
		background_music.play()

# Main play button - goes to first game (Making Words)
func _on_play_button_pressed():
	print("Play button pressed - Starting Making Words Cutscene")
	start_making_words()

# Individual game button functions (if you have separate buttons for each game)
func _on_making_words_button_pressed():
	"""Start Making Words with cutscene"""
	print("Making Words button pressed")
	start_making_words()

func _on_labeling_parts_button_pressed():
	"""Start Labeling Parts with cutscene"""
	print("Labeling Parts button pressed")
	start_labeling_parts()

func _on_finding_words_button_pressed():
	"""Start Finding Words with cutscene"""
	print("Finding Words button pressed")
	start_finding_words()

# Game starter functions
func start_making_words():
	"""Navigate to Making Words cutscene"""
	stop_audio_and_transition(MAKING_WORDS_CUTSCENE)

func start_labeling_parts():
	"""Navigate to Labeling Parts cutscene"""
	stop_audio_and_transition(LABELING_PARTS_CUTSCENE)

func start_finding_words():
	"""Navigate to Finding Words cutscene"""
	stop_audio_and_transition(FINDING_WORDS_CUTSCENE)

func stop_audio_and_transition(scene_path: String):
	"""Stop audio and transition to scene"""
	# Stop audio before transitioning
	if background_music and background_music.playing:
		background_music.stop()
	if welcome_audio and welcome_audio.playing:
		welcome_audio.stop()
	
	# Navigate to the cutscene
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Scene not found: ", scene_path)

# If you have other buttons (settings, quit, etc.)
func _on_settings_button_pressed():
	print("Settings button pressed")
	# Add settings functionality here

func _on_quit_button_pressed():
	print("Quit button pressed")
	get_tree().quit()

# Input handling
func _input(event):
	"""Handle keyboard input"""
	if event.is_action_pressed("ui_cancel"):
		# ESC key - quit game or show quit confirmation
		_on_quit_button_pressed()

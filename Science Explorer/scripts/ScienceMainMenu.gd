# ScienceMainMenu.gd
extends Node2D

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
		background_music.volume_db = -15
		background_music.play()

func _on_play_button_pressed():
	print("Play button pressed - Starting Making Words Cutscene")
	
	# Stop audio before transitioning
	if background_music and background_music.playing:
		background_music.stop()
	if welcome_audio and welcome_audio.playing:
		welcome_audio.stop()
	
	# Navigate to Making Words Cutscene
	get_tree().change_scene_to_file("res://scenes/Scene2_MakingWordsCutscene.tscn")

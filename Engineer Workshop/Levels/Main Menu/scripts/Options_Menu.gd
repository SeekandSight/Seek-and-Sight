# OptionsMenu.gd
# Attach this to the root node of your options menu scene.

extends Node2D

# --- Node Connections ---
# Paths updated to match your scene tree where sliders are children of labels.
@onready var volume_slider: HSlider = $VBoxContainer/HBoxContainer/VolumeLabel/VolumeSlider
@onready var speed_slider: HSlider = $VBoxContainer/HBoxContainer2/SpeedLabel/SpeedSlider
@onready var text_slider: HSlider = $VBoxContainer/HBoxContainer3/TextLabel/TextSlider
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready():

	# 1. Initialize the sliders to show the current settings.
	volume_slider.value = Settings.master_volume
	speed_slider.value = Settings.audio_speed
	text_slider.value = Settings.text_scale

	# 2. Connect the signals from the UI elements.
	volume_slider.value_changed.connect(Settings.set_master_volume)
	speed_slider.value_changed.connect(Settings.set_audio_speed)
	text_slider.value_changed.connect(Settings.set_text_scale)
	back_button.pressed.connect(_on_back_button_pressed)


func _on_back_button_pressed() -> void:
	# Save the settings when leaving the menu.
	Settings.save_settings()
	# Go back to the main menu.
	get_tree().change_scene_to_file("res://Levels/Main Menu/Scenes/Scene1_Welcome.tscn")

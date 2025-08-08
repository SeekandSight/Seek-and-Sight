# Settings.gd
# Add this script as an Autoload (Singleton) to manage game settings.
extends Node2D

const SETTINGS_FILE_PATH = "user://settings.save"

# --- Default Settings ---
var master_volume: float = 0.0  # In decibels. 0.0 is full volume, negative is quieter.
var audio_speed: float = 1.0    # 1.0 is normal speed, > 1.0 is faster, < 1.0 is slower.
var text_scale: float = 1.0     # 1.0 is normal size, > 1.0 is larger.


func _ready():
	load_settings()


# --- Public Functions ---

func set_master_volume(db_value: float):
	master_volume = db_value
	AudioServer.set_bus_volume_db(0, master_volume)
	print("Master volume set to: ", db_value)

func set_audio_speed(speed: float):
	audio_speed = speed
	print("Audio speed set to: ", speed)

func set_text_scale(scale: float):
	text_scale = scale
	print("Text scale set to: ", scale)


# --- Save and Load ---

func save_settings():
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		var settings_data = {
			"master_volume": master_volume,
			"audio_speed": audio_speed,
			"text_scale": text_scale,
		}
		var json_string = JSON.stringify(settings_data)
		file.store_string(json_string)
		print("Settings saved successfully.")

func load_settings():
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		print("No settings file found. Using defaults.")
		set_master_volume(master_volume)
		return

	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var parse_result = JSON.parse_string(content)
		if parse_result:
			var data = parse_result
			set_master_volume(data.get("master_volume", 0.0))
			set_audio_speed(data.get("audio_speed", 1.0))
			set_text_scale(data.get("text_scale", 1.0))
			print("Settings loaded successfully.")
		else:
			printerr("Failed to parse settings file.")

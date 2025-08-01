# This script is designed to be an Autoload (Singleton).
# It tracks player metrics and saves them to a JSON file.
extends Node2D

# --- Player Info ---
var student_id: String = "Not Set"

# --- Metrics ---
# These variables will hold the data we want to track.

# Total time the game has been running, in seconds.
var play_time: float = 0.0

# The player's overall score.
var score: int = 0

# The number of questions the player has answered correctly.
var correct_answers: int = 0

# The number of questions the player has answered incorrectly.
var incorrect_answers: int = 0


# The _process function is called on every frame.
# We use it here to increment the play time.
func _process(delta: float) -> void:
	play_time += delta


# --- Public Functions ---
# These are the functions you will call from other scripts.

# Sets the Student ID. Call this from the main menu.
func set_student_id(id: String) -> void:
	if not id.is_empty():
		student_id = id
	else:
		student_id = "Anonymous" # Default if no name is entered
	print("Student ID set to: ", student_id)

# Resets all tracked data to their default values.
# Call this from your "Start Game" button to ensure every session is fresh.
func reset_analytics() -> void:
	play_time = 0.0
	score = 0
	correct_answers = 0
	incorrect_answers = 0
	print("Analytics data has been reset for new game session.")


# Adds a given number of points to the overall score.
func add_score(points: int) -> void:
	score += points
	print("Score updated: ", score)


# Increments the count of correctly answered questions by one.
func increment_correct_answers() -> void:
	correct_answers += 1
	print("Correct answers: ", correct_answers)


# Increments the count of incorrectly answered questions by one.
func increment_incorrect_answers() -> void:
	incorrect_answers += 1
	print("Incorrect answers: ", incorrect_answers)


# --- Data Saving ---

# Gathers all tracked data, formats it, and saves it to a JSON file.
# This should be called when the game ends or when you want to save progress.
func save_data() -> void:
	# Create a dictionary to hold all our data.
	# Dictionaries are easily converted to JSON.
	var data_to_save = {
		"student_id": student_id, # Use the stored student ID
		"date_played": Time.get_datetime_string_from_system(false, true), # Get current date and time
		"play_time_seconds": play_time,
		"play_time_formatted": _format_seconds_to_hms(play_time), # A more readable time format
		"overall_score": score,
		"questions_answered_correctly": correct_answers,
		"questions_answered_incorrectly": incorrect_answers,
	}

	# Convert the dictionary to a JSON string. The "\t" adds indentation for readability.
	var json_string = JSON.stringify(data_to_save, "\t")

	# Open/create the file in the user's data directory.
	# user:// is a special Godot path that points to a safe place to store user data.
	var file = FileAccess.open("user://analytics_data.json", FileAccess.WRITE)
	if file:
		# Write the JSON string to the file.
		file.store_string(json_string)
		# The file is automatically closed when 'file' goes out of scope.
		print("Analytics data successfully saved to user://analytics_data.json")
	else:
		printerr("An error occurred while trying to save the analytics data.")


# --- Helper Functions ---

# Converts a float value of seconds into a HH:MM:SS string format.
func _format_seconds_to_hms(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) / 60) % 60
	var secs = int(seconds) % 60
	# The "%02d" format ensures that the number is padded with a leading zero if it's less than 10.
	return "%02d:%02d:%02d" % [hours, minutes, secs]

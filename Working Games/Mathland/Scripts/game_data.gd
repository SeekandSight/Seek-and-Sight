extends Node

var player_profile = {
	"player_id": "",
	"player_name": "Player",
	"grade_level": "Kindergarten",
	"created_date": "",
	"total_play_time": 0
}

var game_progress = {
	"number_match_highest_level": 1,  # NEW: Track highest unlocked level
	"number_match_completed_levels": []  # NEW: Array of completed level numbers
}

var game_history = []
var statistics_cache = {}
var grade_levels = ["Kindergarten", "1st Grade", "2nd Grade"]

var current_game_settings = {
	"grade_level": "Kindergarten",
	"game_mode": 0
}

const SAVE_PATH = "user://player_data.json"
const BACKUP_PATH = "user://player_data_backup.json"

func _ready():
	print("=== GameData Autoload Starting ===")
	initialize_player()
	load_all_data()
	print("=== GameData Ready ===")

func initialize_player():
	if player_profile["player_id"].is_empty():
		player_profile["player_id"] = generate_unique_id()
		player_profile["created_date"] = Time.get_datetime_string_from_system()
		print("New player created: ", player_profile["player_id"])

func generate_unique_id() -> String:
	return "%s_%d" % [Time.get_datetime_string_from_system().replace(":", "").replace("-", ""), randi()]

func save_game_result(result: Dictionary):
	var enriched_result = result.duplicate()
	enriched_result["result_id"] = generate_unique_id()
	enriched_result["player_id"] = player_profile["player_id"]
	enriched_result["timestamp"] = Time.get_datetime_string_from_system()
	enriched_result["accuracy"] = calculate_accuracy(enriched_result)
	
	game_history.append(enriched_result)
	player_profile["total_play_time"] += enriched_result.get("time", 0)
	
	# Update level progress for Number Match
	if result["game_name"] == "Number Match" or result["game_name"].begins_with("Number Match"):
		var completed_level = result.get("levels_completed", 1)
		update_level_progress(completed_level)
	
	print("Game result saved: ", enriched_result)
	save_all_data()
	return enriched_result

func update_level_progress(completed_level: int):
	# Update highest level unlocked
	var next_level = completed_level + 1
	if next_level > game_progress["number_match_highest_level"]:
		game_progress["number_match_highest_level"] = next_level
		print("Unlocked level: ", next_level)
	
	# Add to completed levels if not already there
	if not completed_level in game_progress["number_match_completed_levels"]:
		game_progress["number_match_completed_levels"].append(completed_level)
		print("Marked level ", completed_level, " as completed")
	
	save_all_data()

func is_level_unlocked(level: int) -> bool:
	return level <= game_progress["number_match_highest_level"]

func is_level_completed(level: int) -> bool:
	return level in game_progress["number_match_completed_levels"]

func get_highest_unlocked_level() -> int:
	return game_progress["number_match_highest_level"]

func reset_level_progress():
	game_progress["number_match_highest_level"] = 1
	game_progress["number_match_completed_levels"] = []
	save_all_data()
	print("Level progress reset")

func calculate_accuracy(result: Dictionary) -> float:
	var correct = result.get("correct", 0)
	var total = result.get("total", 1)
	return (float(correct) / float(total)) * 100.0 if total > 0 else 0.0

func save_all_data():
	save_to_json(SAVE_PATH, get_save_data())
	save_to_json(BACKUP_PATH, get_save_data())

func get_save_data() -> Dictionary:
	return {
		"version": "1.0",
		"player_profile": player_profile,
		"game_progress": game_progress,  # NEW: Save progress
		"game_history": game_history,
		"save_date": Time.get_datetime_string_from_system()
	}

func load_all_data():
	var data = load_from_json(SAVE_PATH)
	if data.is_empty():
		data = load_from_json(BACKUP_PATH)
	
	if not data.is_empty():
		player_profile = data.get("player_profile", player_profile)
		game_progress = data.get("game_progress", game_progress)  # NEW: Load progress
		game_history = data.get("game_history", [])
		print("Loaded ", game_history.size(), " game results")
		print("Highest unlocked level: ", game_progress["number_match_highest_level"])
	else:
		print("No saved data found, starting fresh")

func save_to_json(path: String, data: Dictionary):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Saved to: ", path)
	else:
		push_error("Failed to save to: " + path)

func load_from_json(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				return json.data
			else:
				push_error("JSON parse error in " + path)
	return {}

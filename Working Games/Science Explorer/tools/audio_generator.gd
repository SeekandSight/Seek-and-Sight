# Save this as: res://tools/audio_generator.gd
# Run this ONCE in Godot Editor: Tools > Execute Script

@tool
extends EditorScript

const MAX_WORDS_PER_LEVEL = 6  # ✅ Limit to 6 words per level

func _run():
	"""Generate audio configuration file for web export compatibility"""
	print("=== GENERATING AUDIO CONFIG FOR WEB EXPORT ===")
	
	var audio_directories = [
		"res://Assets/Audio/First Grade Words/",
		"res://Assets/Audio/Minigame 3/",
		"res://Assets/Audio/Words/",
		"res://Assets/Audio/"
	]
	
	var all_words = {}
	var word_levels = {
		"level_1": [],  # 2-letter words
		"level_2": [],  # 3-letter words  
		"level_3": []   # 4-letter words
	}
	
	var total_files_found = 0
	
	# Scan all directories
	for directory in audio_directories:
		print("📁 Scanning: ", directory)
		var found_in_dir = scan_directory_for_words(directory, all_words)
		total_files_found += found_in_dir
		print("   Found ", found_in_dir, " audio files")
	
	if total_files_found == 0:
		print("❌ NO AUDIO FILES FOUND!")
		print("   Check your directory paths:")
		for dir in audio_directories:
			print("   - ", dir, " exists: ", DirAccess.dir_exists_absolute(dir))
		return
	
	# Organize by word length
	for word in all_words:
		var file_path = all_words[word]
		var word_data = {"word": word, "path": file_path}
		
		match word.length():
			2: word_levels["level_1"].append(word_data)
			3: word_levels["level_2"].append(word_data)
			4: word_levels["level_3"].append(word_data)
	
	# Generate configuration files
	generate_json_config(word_levels, total_files_found)
	generate_backup_text_file(all_words)
	
	print("=== GENERATION COMPLETE ===")
	print("✅ Generated: res://word_config.json")
	print("✅ Generated: res://audio_backup.txt")
	print("📊 Total words: ", all_words.size())
	print("   Level 1 (2-letter): ", word_levels["level_1"].size())
	print("   Level 2 (3-letter): ", word_levels["level_2"].size())
	print("   Level 3 (4-letter): ", word_levels["level_3"].size())
	print("🎮 Your games are now web-compatible!")

func scan_directory_for_words(dir_path: String, word_dict: Dictionary) -> int:
	"""Scan directory and add words to dictionary"""
	var files_found = 0
	
	if not DirAccess.dir_exists_absolute(dir_path):
		print("   ⚠️  Directory not found: ", dir_path)
		return 0
	
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("   ❌ Could not open directory: ", dir_path)
		return 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and is_audio_file(file_name):
			var word = extract_word_from_filename(file_name)
			
			# Only include 2-4 letter words
			if word.length() >= 2 and word.length() <= 4:
				# Avoid duplicates - keep first found
				if word not in word_dict:
					word_dict[word] = dir_path + file_name
					print("     ✅ ", word, " -> ", file_name)
					files_found += 1
				else:
					print("     🔄 Duplicate: ", word, " (keeping first found)")
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files_found

func generate_json_config(levels: Dictionary, total_files: int):
	"""Generate JSON configuration file with 6 words per level"""
	var config = {
		"metadata": {
			"generated_at": Time.get_datetime_string_from_system(),
			"total_files": total_files,
			"generator_version": "1.0",
			"description": "Auto-generated audio configuration for web export"
		},
		"audio_settings": {
			"preferred_format": "ogg",
			"fallback_formats": ["wav", "mp3"],
			"web_compatible": true
		},
		"levels": {
			"level_1": {
				"description": "Easy 2-letter words",
				"difficulty": "beginner",
				"target_age": "4-6 years",
				"words": {}
			},
			"level_2": {
				"description": "Medium 3-letter words", 
				"difficulty": "intermediate",
				"target_age": "5-7 years",
				"words": {}
			},
			"level_3": {
				"description": "Hard 4-letter words",
				"difficulty": "advanced",
				"target_age": "6-8 years",
				"words": {}
			}
		}
	}
	
	# ✅ Limit to 6 words per level
	for level_name in levels:
		var words_added = 0
		for word_data in levels[level_name]:
			if words_added >= MAX_WORDS_PER_LEVEL:
				break
			var word = word_data["word"]
			var path = word_data["path"]
			config["levels"][level_name]["words"][word] = path
			words_added += 1
	
	# Save JSON file
	var json_string = JSON.stringify(config, "\t")
	var file = FileAccess.open("res://word_config.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("💾 Saved JSON config")
	else:
		print("❌ Failed to save JSON config")

func generate_backup_text_file(words: Dictionary):
	"""Generate simple backup text file"""
	var file = FileAccess.open("res://audio_backup.txt", FileAccess.WRITE)
	if file:
		file.store_line("# Auto-generated audio backup list")
		file.store_line("# Format: word|full_path")
		file.store_line("# Generated: " + Time.get_datetime_string_from_system())
		file.store_line("")
		
		for word in words:
			file.store_line(word + "|" + words[word])
		
		file.close()
		print("💾 Saved backup text file")

func is_audio_file(filename: String) -> bool:
	var extensions = [".wav", ".ogg", ".mp3", ".WAV", ".OGG", ".MP3"]
	for ext in extensions:
		if filename.ends_with(ext):
			return true
	return false

func extract_word_from_filename(filename: String) -> String:
	var word = filename
	var extensions = [".wav", ".ogg", ".mp3", ".WAV", ".OGG", ".MP3"]
	for ext in extensions:
		if word.ends_with(ext):
			word = word.substr(0, word.length() - ext.length())
			break
	return word.to_lower()

extends Node2D

# Finding Words Cutscene Script - FINAL CORRECTED VERSION

const FINDING_WORDS_GAME = "res://scenes/Scene7_FindingWordsGame.tscn"
const LABELING_PARTS_GAME = "res://scenes/Scene3_LabelingPartsGame.tscn"

var dialogue_index = 0

# CORRECTED DIALOGUE ORDER - matches your story flow
var dialogues_with_audio = [
	{
		"text": "Greetings, young archaeologist! I'm Dr. Sunny, and I need your help with an amazing discovery!",
		"audio": "res://Assets/Audio/Minigame 3/Greetings, young archaeologist! I'm Sandy Sparks, and I need your help with an amazing discovery!.wav"
	},
	{
		"text": "We've found an ancient dig site where magical words are buried deep in the sand!",
		"audio": "res://Assets/Audio/Minigame 3/We've found an ancient dig site where magical words are buried deep in the sand!.wav"
	},
	{
		"text": "These aren't ordinary words - they're sight words that will help you become a better reader!",
		"audio": "res://Assets/Audio/Minigame 3/These aren't ordinary words - they're sight words that will help you become a better reader!.wav"
	},
	{
		"text": "Here's how our word archaeology works: I'll speak a word, you'll see options buried in sand, and you click the correct one!",
		"audio": "res://Assets/Audio/Minigame 3/Here's how our word archaeology works_ I'll speak a word, you'll see options buried in sand, and you click the correct one!.wav"
	},
	{
		"text": "Think of it like a treasure hunt - but instead of gold, we're digging up valuable words!",
		"audio": "res://Assets/Audio/Minigame 3/Think of it like a treasure hunt - but instead of gold, we're digging up valuable words!.wav"
	},
	{
		"text": "Let's start with easy 2-letter words, then move to harder 3 and 4-letter words!",
		"audio": "res://Assets/Audio/Minigame 3/Let's start with easy 2-letter words, then move to harder 3 and 4-letter words!.wav"
	},
	{
		"text": "Are you ready to begin your word archaeology expedition?",
		"audio": "res://Assets/Audio/Minigame 3/Are you ready to begin your word archaeology expedition_.wav"
	}
]

@onready var dialogue_text = $UI/DialoguePanel/DialogueText
@onready var continue_button = $UI/DialoguePanel/ContinueButton
@onready var back_button = $UI/BackButton
@onready var skip_button = $UI/SkipButton
@onready var title_label = $UI/Title

# Audio references - will be null if nodes don't exist (graceful handling)
@onready var dialogue_audio = $Audio/DialogueAudio
@onready var background_music = $Audio/BackgroundMusic

func _ready():
	print("=== FINDING WORDS CUTSCENE - FINAL VERSION ===")
	
	# Debug node status
	print("Dialogue text found: ", dialogue_text != null)
	print("Continue button found: ", continue_button != null)
	print("Audio nodes found: ", dialogue_audio != null, " / ", background_music != null)
	
	setup_ui_visibility()
	setup_audio()
	update_dialogue()

func setup_ui_visibility():
	"""Ensure UI elements are visible"""
	if dialogue_text:
		dialogue_text.visible = true
		dialogue_text.modulate = Color.WHITE
		print("✅ Dialogue text ready")
	
	if continue_button:
		continue_button.visible = true
		continue_button.modulate = Color.WHITE
		print("✅ Continue button ready")
	
	if back_button:
		back_button.visible = true
		back_button.modulate = Color.WHITE
	
	if title_label:
		title_label.visible = true
		title_label.modulate = Color.WHITE

func setup_audio():
	"""Setup background music (optional)"""
	if background_music:
		# Try to find a background music file
		var bg_paths = [
			"res://Assets/Audio/Background1.mp3",
			"res://Assets/Audio/Background2.mp3",
			"res://Assets/Audio/Sandy Sparks Flower (Temp).mp3"
		]
		
		for bg_path in bg_paths:
			if ResourceLoader.exists(bg_path):
				background_music.stream = load(bg_path)
				background_music.volume_db = -20
				background_music.play()
				print("✅ Background music started: ", bg_path.get_file())
				break
	else:
		print("⚠️ No background music node - skipping")

func update_dialogue():
	"""Update dialogue text and play corresponding audio"""
	if dialogue_index < dialogues_with_audio.size():
		var dialogue_data = dialogues_with_audio[dialogue_index]
		var text = dialogue_data["text"]
		var audio_path = dialogue_data["audio"]
		
		print("=== Dialogue ", dialogue_index + 1, "/", dialogues_with_audio.size(), " ===")
		print("Text: ", text.substr(0, 50), "...")
		
		# Update text
		if dialogue_text:
			dialogue_text.text = text
		
		# Play corresponding audio (if audio node exists)
		if dialogue_audio:
			play_dialogue_audio(audio_path)
		else:
			print("⚠️ No dialogue audio node - showing text only")
		
		# Update button text
		if continue_button:
			if dialogue_index == dialogues_with_audio.size() - 1:
				continue_button.text = "Start Game!"
			else:
				continue_button.text = "Continue"
	else:
		start_game()

func play_dialogue_audio(audio_path: String):
	"""Play audio for current dialogue line"""
	print("🔍 Checking audio: ", audio_path.get_file())
	
	if ResourceLoader.exists(audio_path):
		# Stop current audio if playing
		if dialogue_audio.playing:
			dialogue_audio.stop()
		
		# Load and play new audio
		var audio_stream = load(audio_path)
		if audio_stream:
			dialogue_audio.stream = audio_stream
			dialogue_audio.volume_db = -5
			dialogue_audio.play()
			print("🔊 Playing audio successfully!")
		else:
			print("❌ Failed to load audio stream")
	else:
		print("❌ Audio file not found: ", audio_path)

func _on_continue_pressed():
	"""Handle continue button press"""
	print("Continue button pressed")
	
	# Stop current audio before moving to next
	if dialogue_audio and dialogue_audio.playing:
		dialogue_audio.stop()
	
	dialogue_index += 1
	update_dialogue()

func _on_back_button_pressed():
	"""Go back to Labeling Parts Game"""
	print("Back button pressed")
	stop_all_audio()
	get_tree().change_scene_to_file(LABELING_PARTS_GAME)

func _on_skip_pressed():
	"""Skip to game"""
	print("Skip button pressed")
	start_game()

func start_game():
	"""Start the main game"""
	print("Starting Finding Words game")
	stop_all_audio()
	
	if ResourceLoader.exists(FINDING_WORDS_GAME):
		get_tree().change_scene_to_file(FINDING_WORDS_GAME)
	else:
		print("❌ Finding Words game not found, going back to Labeling Parts")
		get_tree().change_scene_to_file(LABELING_PARTS_GAME)

func stop_all_audio():
	"""Stop all audio before scene transition"""
	if background_music and background_music.playing:
		background_music.stop()
	if dialogue_audio and dialogue_audio.playing:
		dialogue_audio.stop()
	print("Audio stopped")

func _input(event):
	"""Handle input"""
	if event.is_action_pressed("ui_accept"):
		_on_continue_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
	elif event.is_action_pressed("ui_select"):
		_on_skip_pressed()

func _exit_tree():
	"""Cleanup when exiting scene"""
	stop_all_audio()

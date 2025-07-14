extends Node2D

# Simple Finding Words Cutscene - Corrected Navigation
# Minimal setup to ensure text is visible

# Scene paths - CORRECTED BACK NAVIGATION
const FINDING_WORDS_GAME = "res://scenes/Scene7_FindingWordsGame.tscn"
const LABELING_PARTS_GAME = "res://scenes/Scene3_LabelingPartsGame.tscn"  # Back goes to previous game

var dialogue_index = 0
var dialogues = [
	"Greetings, young archaeologist! I'm Dr. Sunny, and I need your help with an amazing discovery!",
	"We've found an ancient dig site where magical words are buried deep in the sand!",
	"These aren't ordinary words - they're sight words that will help you become a better reader!",
	"Here's how our word archaeology works: I'll speak a word, you'll see options buried in sand, and you click the correct one!",
	"Think of it like a treasure hunt - but instead of gold, we're digging up valuable words!",
	"Let's start with easy 2-letter words, then move to harder 3 and 4-letter words!",
	"Are you ready to begin your word archaeology expedition?"
]

@onready var dialogue_text = $UI/DialoguePanel/DialogueText
@onready var continue_button = $UI/DialoguePanel/ContinueButton
@onready var back_button = $UI/BackButton
@onready var skip_button = $UI/SkipButton
@onready var title_label = $UI/Title

func _ready():
	print("=== FINDING WORDS CUTSCENE ===")
	print("Dialogue text node: ", dialogue_text)
	print("Continue button: ", continue_button)
	print("Back button: ", back_button)
	print("Title label: ", title_label)
	
	# Force visibility
	if dialogue_text:
		dialogue_text.visible = true
		dialogue_text.modulate = Color.WHITE
	if continue_button:
		continue_button.visible = true
		continue_button.modulate = Color.WHITE
	if back_button:
		back_button.visible = true
		back_button.modulate = Color.WHITE
	if title_label:
		title_label.visible = true
		title_label.modulate = Color.WHITE
	
	# Set initial dialogue
	update_dialogue()

func update_dialogue():
	"""Update the dialogue text"""
	if dialogue_index < dialogues.size():
		var text = dialogues[dialogue_index]
		print("Setting dialogue ", dialogue_index, ": ", text)
		
		if dialogue_text:
			dialogue_text.text = text
		
		if continue_button:
			if dialogue_index == dialogues.size() - 1:
				continue_button.text = "Start Game!"
			else:
				continue_button.text = "Continue"
	else:
		start_game()

func _on_continue_pressed():
	"""Handle continue button press"""
	print("Continue pressed, dialogue index: ", dialogue_index)
	dialogue_index += 1
	update_dialogue()

# CORRECTED: Back goes to Labeling Parts Game (previous scene in sequence)
func _on_back_button_pressed():
	"""Go back to Labeling Parts Game"""
	print("Going back to Labeling Parts Game from Finding Words cutscene")
	get_tree().change_scene_to_file(LABELING_PARTS_GAME)

func _on_skip_pressed():
	"""Skip to game"""
	print("Skip pressed")
	start_game()

func start_game():
	"""Start the main game"""
	print("Starting Finding Words game")
	
	if ResourceLoader.exists(FINDING_WORDS_GAME):
		get_tree().change_scene_to_file(FINDING_WORDS_GAME)
	else:
		print("Game scene not found, going back to Labeling Parts")
		get_tree().change_scene_to_file(LABELING_PARTS_GAME)

func _input(event):
	"""Handle input"""
	if event.is_action_pressed("ui_accept"):
		_on_continue_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
	elif event.is_action_pressed("ui_select"):
		_on_skip_pressed()

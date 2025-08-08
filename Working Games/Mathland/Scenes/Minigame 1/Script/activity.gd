extends Node

@onready var words_container = $Words
@onready var numbers_container = $Numbers


const NumberSlotScene = preload("res://Scenes/Minigame 1/Scene/number_slot.tscn")
const WordSlotScene = preload("res://Scenes/Minigame 1/Scene/word_slot.tscn")

var numbers = [1,2,3,4,5,6,7,8,9,10]
var total_matches := 4
var correct_matches := 0

func _ready():
	numbers.shuffle()
	var chosen = numbers.slice(0, 4)
	var word_order = chosen.duplicate()
	word_order.shuffle()

	for i in range(chosen.size()):
		var num_slot = NumberSlotScene.instantiate()
		num_slot.value = chosen[i]
		num_slot.position = Vector2(150 + i * 150, 100)  # ← adjust X spacing
		numbers_container.add_child(num_slot)

		var word_slot = WordSlotScene.instantiate()
		word_slot.correct_number = word_order[i]
		word_slot.position = Vector2(150 + i * 150, 300)
		words_container.add_child(word_slot)
		
func _on_word_solved():
	correct_matches += 1
	if correct_matches >= total_matches:
		load_next_scene()
		
func load_next_scene():
	var next_scene = preload("res://Scenes/Cutscene 2/Scene/cutscene_2.tscn")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_packed(next_scene)

extends Node

@onready var names_container = $Names
@onready var shapes_container = $Shapes

const NameSlotScene = preload("res://Scenes/Minigame 2/Scene/name_slot.tscn")
const ShapeSlotScene = preload("res://Scenes/Minigame 2/Scene/shape_slot.tscn")

var names = ["square", "triangle", "circle", "heart", "diamond", "star"]
var total_matches := 4
var correct_matches := 0

func _ready():
	names.shuffle()
	var chosen = names.slice(0, 4)
	var shape_order = chosen.duplicate()
	shape_order.shuffle()

	for i in range(chosen.size()):
		var name_slot = NameSlotScene.instantiate()
		name_slot.value = chosen[i]
		name_slot.position = Vector2(150 + i * 150, 100)  # ← adjust X spacing
		names_container.add_child(name_slot)

		var shape_slot = ShapeSlotScene.instantiate()
		shape_slot.correct_name = shape_order[i]
		shape_slot.position = Vector2(150 + i * 150, 300)
		shapes_container.add_child(shape_slot)
		
func _on_word_solved():
	correct_matches += 1
	if correct_matches >= total_matches:
		load_next_scene()
		
func load_next_scene():
	var next_scene = preload("res://Scenes/Cutscene 3/Scene/cutscene_3.tscn")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_packed(next_scene)

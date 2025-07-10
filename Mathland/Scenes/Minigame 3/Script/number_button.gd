extends Control

@export var value: int = 0
@export var correct := false
@onready var button: Button = $Button

func _ready():
	button.text = str(value)

func get_correct():
	return correct
	
func set_correct(new_value:bool):
	correct = new_value

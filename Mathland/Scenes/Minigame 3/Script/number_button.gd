extends Control

@export var value: int = 0
@onready var button: Button = $Button

func _ready():
	button.text = str(value)

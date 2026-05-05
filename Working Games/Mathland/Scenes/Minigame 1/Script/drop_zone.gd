extends Control

var word_value = ""
var is_completed = false

@onready var word_label = get_node_or_null("WordLabel")
@onready var completed_indicator = get_node_or_null("CompletedIndicator")
@onready var background = get_node_or_null("Border/Background")
@onready var border = get_node_or_null("Border")

func _ready():
	add_to_group("drop_zones")

func set_word(word: String):
	word_value = word
	if word_label:
		word_label.text = word

func mark_completed():
	is_completed = true
	
	# Animate the completion
	if word_label:
		var fade_tween = create_tween()
		fade_tween.tween_property(word_label, "modulate", Color(1, 1, 1, 0), 0.3)
	
	if completed_indicator:
		completed_indicator.visible = true
		completed_indicator.modulate = Color(1, 1, 1, 0)
		var appear_tween = create_tween()
		appear_tween.tween_property(completed_indicator, "modulate", Color(1, 1, 1, 1), 0.3)
	
	if background:
		var color_tween = create_tween()
		color_tween.tween_property(background, "color", Color(0.7, 1, 0.75, 1), 0.3)
	
	if border:
		var border_tween = create_tween()
		border_tween.tween_property(border, "color", Color(0, 0.6, 0, 1), 0.3)

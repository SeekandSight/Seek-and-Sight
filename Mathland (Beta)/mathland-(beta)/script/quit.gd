extends TextureButton

var original_scale := Vector2.ONE
var hover_scale := Vector2(1.2, 1.2)
var tween: Tween

func _ready():
	original_scale = scale
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.2)

func _on_mouse_exited():
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", original_scale, 0.2)
	

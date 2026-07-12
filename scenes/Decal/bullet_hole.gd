extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.tween_interval(5)
	tween.tween_property(self, "modulate:a", 0.0, 5)
	tween.finished.connect(queue_free)

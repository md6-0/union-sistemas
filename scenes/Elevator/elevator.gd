extends AnimatableBody3D

@export var travel_lenght = 10

@onready var origin_position_y = global_position.y
@onready var destination_position_y = global_position.y + travel_lenght
var is_in_origin = true
var is_transitioning = false

func activate():
	if is_transitioning:
		return
		
	_handle_elevator_state()
	if is_in_origin:
		var tween1 = create_tween()
		tween1.tween_property(self, "global_position:y", destination_position_y , 10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween1.finished.connect(_handle_elevator_state)
		is_in_origin = false
	else:
		var tween2 = create_tween()
		tween2.tween_property(self, "global_position:y", origin_position_y , 10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween2.finished.connect(_handle_elevator_state)
		is_in_origin = true

func _handle_elevator_state():
	is_transitioning = not is_transitioning

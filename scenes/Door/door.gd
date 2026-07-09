extends Node3D

@export var required_key: String = ""

var is_open = false
var target = 90

func interact(_camera):
	
	if required_key == "" or GameManager.inventory.get(required_key, 0) > 0:
		if is_open:
			target = 0
		else:
			target = 90
		
		var tween = create_tween()
		#rotation:y, deg_to_rad(target)
		tween.tween_property(self, "global_position:z", 10 , 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(_handle_door_state)

func _handle_door_state():
	if required_key != "" and GameManager.inventory.has(required_key):
		GameManager.inventory[required_key] -= 1

	required_key = ""
	is_open = not is_open 

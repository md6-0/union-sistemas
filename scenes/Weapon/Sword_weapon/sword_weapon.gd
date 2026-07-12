class_name SwordWeapon extends WeaponBase

var original_rotation
var original_position

func pick_up(camera):
	super.pick_up(camera)
	position = Vector3(-.5,-.5,-.5)
	rotation = Vector3(deg_to_rad(80), deg_to_rad(-25), 0)
	original_rotation = rotation
	original_position = position

func try_attack():	
	if time_since_last_attack >= cooldown:
		time_since_last_attack = 0
		var tween = create_tween().set_parallel(true)
		# ── el tajo: todo simultáneo, rápido, acelerando ──
		tween.tween_property(self, "rotation:x", original_rotation.x - deg_to_rad(100), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "rotation:y", original_rotation.y - deg_to_rad(70), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "position:x", original_position.x + 1, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# ── la vuelta: encadenada tras el tajo, lenta, frenando ──
		tween.chain().tween_property(self, "rotation", original_rotation, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", original_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)  

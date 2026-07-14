class_name SwordWeapon extends WeaponBase

var original_rotation
var original_position
var attack_tween

@onready var area3D_hitbox = $Area3D_hitbox
@onready var audioStreamPlayer_hit = $AudioStreamPlayer_hit
@onready var audioStreamPlayer_pickup = $AudioStreamPlayer_pickup

var already_hit = []


func _ready():
	area3D_hitbox.body_entered.connect(_on_area3D_hitbox_body_entered)

func pick_up(camera, new_holder = null):
	super.pick_up(camera, new_holder)
	position = Vector3(-.5,-.5,-.5)
	rotation = Vector3(deg_to_rad(80), deg_to_rad(-25), 0)
	original_rotation = rotation
	original_position = position
	audioStreamPlayer_pickup.pitch_scale = randf_range(0.9, 1.1)
	audioStreamPlayer_pickup.play()
	
func drop():
	super.drop()
	if attack_tween and attack_tween.is_running():
		attack_tween.kill()
	area3D_hitbox.monitoring = false
	audioStreamPlayer_pickup.pitch_scale = randf_range(0.9, 1.1)
	audioStreamPlayer_pickup.play()

func try_attack():
	if time_since_last_attack >= cooldown:
		# tajo - golpe
		already_hit.clear()
		time_since_last_attack = 0
		GameManager.weapon_fired.emit()
		audioStreamPlayer_hit.pitch_scale = randf_range(0.9, 1.1)
		audioStreamPlayer_hit.play()
		area3D_hitbox.monitoring = true
		attack_tween = create_tween().set_parallel(true)
		attack_tween.tween_property(self, "rotation:x", original_rotation.x - deg_to_rad(60), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack_tween.tween_property(self, "rotation:y", original_rotation.y - deg_to_rad(60), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack_tween.tween_property(self, "position:x", original_position.x + 2, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack_tween.tween_property(self, "position:z", original_position.z - 2.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# apagamos la hitbox
		attack_tween.chain().tween_callback(func(): area3D_hitbox.monitoring = false)
		# tajo - vuelta a la posición original
		attack_tween.tween_property(self, "rotation", original_rotation, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		attack_tween.tween_property(self, "position", original_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)  
		
func _on_area3D_hitbox_body_entered(body):
	if body in already_hit:
		return
		
	already_hit.append(body) 
	if body.is_in_group("enemy"):
		var was_damage = body.take_damage(damage, global_position, holder, true)
		if was_damage:
			GameManager.enemy_hit.emit()
		else:
			audioStreamPlayer_hit.stop()

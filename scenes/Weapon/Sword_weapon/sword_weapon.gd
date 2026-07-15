class_name SwordWeapon extends WeaponBase

var pose_left_position
var pose_left_rotation
var pose_right_position
var pose_right_rotation
var is_in_left_hand = true

var original_rotation
var original_position
var attack_tween
var thrust_tween
var tilt_tween

@onready var area3D_hitbox = $Area3D_hitbox
@onready var audioStreamPlayer_hit = $AudioStreamPlayer_hit
@onready var audioStreamPlayer_pickup = $AudioStreamPlayer_pickup

var already_hit = []


func _ready():
	area3D_hitbox.body_entered.connect(_on_area3D_hitbox_body_entered)

func pick_up(camera, new_holder = null):
	super.pick_up(camera, new_holder)
	is_in_left_hand = true
	pose_left_position = Vector3(-1.6,-.6,-1)
	pose_left_rotation = Vector3(deg_to_rad(60), deg_to_rad(0), 0)
	pose_right_position = Vector3(-pose_left_position.x, pose_left_position.y, pose_left_position.z)
	pose_right_rotation = Vector3(pose_left_rotation.x, -pose_left_rotation.y, pose_left_rotation.z)
	position = pose_left_position
	rotation = pose_left_rotation
	audioStreamPlayer_pickup.pitch_scale = randf_range(0.9, 1.1)
	audioStreamPlayer_pickup.play()
	
func drop():
	super.drop()
	if attack_tween and attack_tween.is_running():
		attack_tween.kill()
	if thrust_tween and thrust_tween.is_running():
		thrust_tween.kill()
	if tilt_tween and tilt_tween.is_running():
		tilt_tween.kill()
		
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
		
		var position_target
		var rotation_target
		if is_in_left_hand:
			position_target = pose_right_position
			rotation_target = pose_right_rotation
		else:			
			position_target = pose_left_position
			rotation_target = pose_left_rotation
			
		area3D_hitbox.monitoring = true
		attack_tween = create_tween().set_parallel(true)

		# X e Y llevan el barrido lateral; la Z va al thrust_tween, la rotación X al tilt_tween
		attack_tween.tween_property(self, "position:x", position_target.x, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack_tween.tween_property(self, "position:y", position_target.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# empuje hacia delante, sincronizado con la misma duración total que el barrido (0.12s)
		thrust_tween = create_tween()
		thrust_tween.tween_property(self, "position:z", position.z - .25, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		thrust_tween.chain().tween_property(self, "position:z", position_target.z, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tilt_tween = create_tween()
		tilt_tween.tween_property(self, "rotation:x", deg_to_rad(5.0), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tilt_tween.chain().tween_property(self, "rotation:x", rotation_target.x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# apagamos la hitbox
		attack_tween.chain().tween_callback(func(): area3D_hitbox.monitoring = false)
		
		is_in_left_hand = not is_in_left_hand
		
func _on_area3D_hitbox_body_entered(body):
	if body in already_hit:
		return
		
	already_hit.append(body) 
	if body.is_in_group("enemy"):
		var was_damage = body.take_damage(damage, global_position, holder, true)
		if was_damage:
			GameManager.enemy_hit.emit()
			GameManager.hitstop()
		else:
			audioStreamPlayer_hit.stop()

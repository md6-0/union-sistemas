class_name HitscanWeapon extends WeaponBase

@export var pellets = 1
@export var spread = 0.0
@export var shoot_sound = preload("res://Audio/Weapons/pistol_fire.ogg")

@onready var ray_shoot = $RayCast3D_shoot
@onready var ray_shoot_original_target_position = ray_shoot.target_position
@onready var audioStreamPlayer = $AudioStreamPlayer

const BULLET_HOLE = preload("res://scenes/Decal/bullet_hole.tscn")

func _ready():
	audioStreamPlayer.stream = shoot_sound

func pick_up(camera, new_holder = null):
	super.pick_up(camera, new_holder)
	ray_shoot.position = -base_position

func try_attack():
	if time_since_last_attack >= cooldown:
		time_since_last_attack = 0
		GameManager.weapon_fired.emit()
		audioStreamPlayer.pitch_scale = randf_range(0.9, 1.1)
		audioStreamPlayer.play()
		var any_hit = false
		for x in pellets:
			ray_shoot.target_position = ray_shoot_original_target_position + Vector3(randf_range(-spread, spread), randf_range(-spread, spread), 0)
			ray_shoot.force_raycast_update()
			if ray_shoot.is_colliding():
				var collider = ray_shoot.get_collider()
				if collider != null and collider.is_in_group("enemy"):
					var was_damage = collider.take_damage(damage, global_position, holder, false)
					if was_damage:
						any_hit = true
					
				var hole = BULLET_HOLE.instantiate()
				collider.add_child(hole)   
				hole.global_position = ray_shoot.get_collision_point()
				var normal = ray_shoot.get_collision_normal()
				var up_reference = Vector3.UP
				if abs(normal.y) > 0.99:
					up_reference = Vector3.FORWARD
				hole.look_at(hole.global_position + normal, up_reference)
				hole.rotate_object_local(Vector3.RIGHT, -PI/2)
				
			ray_shoot.target_position = ray_shoot_original_target_position
			
		if any_hit:
			GameManager.enemy_hit.emit()

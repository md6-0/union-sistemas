extends Node3D

@export var cooldown = 0.3
@export var damage = 25

@onready var time_since_last_shot = cooldown
@onready var ray_shoot = $RayCast3D_shoot

func _physics_process(delta):
	time_since_last_shot += delta

func try_shoot(delta):
	if time_since_last_shot >= cooldown:
		time_since_last_shot = 0
		if ray_shoot.is_colliding():
			var collider = ray_shoot.get_collider()
			if collider != null and collider.is_in_group("enemy"):
				collider.take_damage(damage)

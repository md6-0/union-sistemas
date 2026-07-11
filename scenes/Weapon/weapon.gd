extends RigidBody3D

@export var cooldown = 0.3
@export var damage = 25

@onready var time_since_last_shot = cooldown
@onready var ray_shoot = $RayCast3D_shoot
@onready var collisionShape = $CollisionShape3D
@onready var original_parent = get_parent()

const BULLET_HOLE = preload("res://scenes/Decal/bullet_hole.tscn")

func _physics_process(delta):
	time_since_last_shot += delta


func pick_up(camera):
	freeze = true
	collisionShape.disabled = true
	reparent(camera)
	position = Vector3(0,-.5,-.5)
	rotation = Vector3.ZERO

func drop():
		freeze = false
		collisionShape.disabled = false
		reparent(original_parent)
		
func try_shoot(delta):
	if time_since_last_shot >= cooldown:
		time_since_last_shot = 0
		if ray_shoot.is_colliding():
			var collider = ray_shoot.get_collider()
			if collider != null and collider.is_in_group("enemy"):
				collider.take_damage(damage)
			
			var hole = BULLET_HOLE.instantiate()
			collider.add_child(hole)   
			hole.global_position = ray_shoot.get_collision_point()
			var normal = ray_shoot.get_collision_normal()
			hole.look_at(hole.global_position + normal, Vector3.UP)
			hole.rotate_object_local(Vector3.RIGHT, -PI/2)

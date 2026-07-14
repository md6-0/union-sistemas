class_name WeaponBase extends RigidBody3D

@export var cooldown = 0.3
@export var damage = 25
@onready var time_since_last_attack = cooldown
@onready var collisionShape = $CollisionShape3D
@onready var original_parent = get_parent()


var holder


func _physics_process(delta):
	time_since_last_attack += delta


func pick_up(camera, new_holder = null):
	freeze = true
	collisionShape.disabled = true
	reparent(camera)
	holder = new_holder
	position = Vector3(0,-.5,-.5)
	rotation = Vector3.ZERO
		
func drop():
	freeze = false
	collisionShape.disabled = false
	holder = null
	reparent(original_parent)

		
func try_attack():
	pass

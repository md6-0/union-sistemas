class_name WeaponBase extends RigidBody3D

const SPARKS = preload("res://scenes/Decal/sparks.tscn")
const BULLET_HOLE = preload("res://scenes/Decal/bullet_hole.tscn")

@export var cooldown = 0.3
@export var damage = 25
@onready var time_since_last_attack = cooldown
@onready var collisionShape = $CollisionShape3D
@onready var original_parent = get_parent()

var holder

@onready var base_position = position
@onready var base_rotation = rotation

@export var sway_amount = 2
@export var sway_speed = 2
@export var sway_max = 8
var sway_target = Vector3.ZERO

func apply_look_sway(_look_x, _look_y):
	pass

func _process(delta):
	if holder == null:
		return
	else:
		sway_target = sway_target.lerp(Vector3.ZERO, sway_speed * delta)
		position = base_position
		rotation = base_rotation + sway_target

func _physics_process(delta):
	time_since_last_attack += delta

func pick_up(camera, new_holder = null):
	freeze = true
	collisionShape.disabled = true
	reparent(camera)
	holder = new_holder
	
	position = Vector3(0,-.5,-1)
	rotation = Vector3.ZERO
	
	base_position = position
	base_rotation = rotation

func drop():
	freeze = false
	collisionShape.disabled = false
	holder = null
	reparent(original_parent)

func try_attack():
	pass
	
	
func _add_decall(parent, at_position: Vector3, normal: Vector3 = Vector3.UP):
	var hole = BULLET_HOLE.instantiate()
	parent.add_child(hole)   
	hole.global_position = at_position
	var up_reference = Vector3.UP
	if abs(normal.y) > 0.99:
		up_reference = Vector3.FORWARD
	hole.look_at(hole.global_position + normal, up_reference)
	hole.rotate_object_local(Vector3.RIGHT, -PI/2)

func _add_sparks(parent, at_position: Vector3, normal: Vector3 = Vector3.UP):
	var sparks = SPARKS.instantiate()
	parent.add_child(sparks)   
	sparks.global_position = at_position
	var up_reference = Vector3.UP
	if abs(normal.y) > 0.99:
		up_reference = Vector3.FORWARD
	sparks.look_at(sparks.global_position + normal, up_reference)

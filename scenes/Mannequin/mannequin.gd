extends StaticBody3D

enum State {IDLE, BLOCK}
enum FeedbackType { HIT, BLOCKED, PARRY }

@onready var label_health = $Label3D_health

@onready var shield_mesh = $MeshInstance3D_Shield
@onready var shield_material = shield_mesh.get_surface_override_material(0)
@onready var shield_base_color = shield_material.albedo_color

@onready var body_mesh = $MeshInstance3D_body
@onready var body_material = body_mesh.get_surface_override_material(0)
@onready var body_base_color = body_material.albedo_color


var health = 10000
var current_state
var current_time_in_state = 0.0
var max_time_in_state = 3
var max_parry_time = .3

var idle_shield_rotation
var idle_shield_position
var block_shield_rotation
var block_shield_position
var shield_tween

var feedback_tween_body
var feedback_tween_shield

func _ready():
	label_health.text = str(health)
	block_shield_rotation = shield_mesh.rotation
	block_shield_position = shield_mesh.position
	idle_shield_rotation =  Vector3(deg_to_rad(90),0,0)
	idle_shield_position =  Vector3(.6,.2,0)
	_change_state(State.IDLE)

func _physics_process(delta):
	_handle_state(delta)

func _handle_state(delta):
	if current_state == State.IDLE:
		_handle_idle_state(delta)
	elif current_state == State.BLOCK:
		_handle_block_state(delta)

func _handle_idle_state(delta):
	current_time_in_state += delta
	if current_time_in_state >= max_time_in_state:
		_change_state(State.BLOCK)

func _handle_block_state(delta):
	current_time_in_state += delta
	if current_time_in_state >= max_time_in_state:
		_change_state(State.IDLE)

func _change_state(new_state):
	current_state = new_state
	if shield_tween and shield_tween.is_running(): 
		shield_tween.kill()

	shield_tween = create_tween().set_parallel(true)
	match new_state:
		State.IDLE:
			current_time_in_state = 0
			shield_tween.tween_property(shield_mesh, "rotation", idle_shield_rotation, 0.3)
			shield_tween.tween_property(shield_mesh, "position", idle_shield_position, 0.3) 
		State.BLOCK:
			current_time_in_state = 0
			shield_tween.tween_property(shield_mesh, "rotation", block_shield_rotation, 0.3)
			shield_tween.tween_property(shield_mesh, "position", block_shield_position, 0.3)

func take_damage(damage, from_position = null, holder = null, allow_parry = false):
	if current_state == State.BLOCK and from_position != null:
		var vector_to_attack = (from_position - global_position)
		vector_to_attack.y = 0 
		var vector_forward = -global_transform.basis.z
		if vector_forward.angle_to(vector_to_attack) < deg_to_rad(80):
			if allow_parry and current_time_in_state <= max_parry_time and holder != null:
				_disarm.call_deferred(holder,vector_to_attack)
				_hit_feedback(FeedbackType.PARRY)
			else:
				_hit_feedback(FeedbackType.BLOCKED)
			return false
			
	health -= damage
	label_health.text = str(health)
	_hit_feedback(FeedbackType.HIT)
	return true

func _disarm(holder, vector_to_attack):
	var w = holder.weapon
	holder.drop_weapon()
	w.apply_central_impulse((vector_to_attack.normalized() + Vector3.UP) * 5)

func _hit_feedback(feedback_type):
	match feedback_type:
		FeedbackType.HIT:
			if feedback_tween_body and feedback_tween_body.is_running():
				feedback_tween_body.kill()
				
			feedback_tween_body = create_tween().set_parallel(true)
			feedback_tween_body.tween_property(body_mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.05)
			feedback_tween_body.tween_property(body_material, "albedo_color", Color("#f92a53e3") , 0.05)
			feedback_tween_body.chain().tween_property(body_mesh, "scale", Vector3.ONE, 0.15)
			feedback_tween_body.tween_property(body_material, "albedo_color", body_base_color, 0.15)
			
		FeedbackType.PARRY:
			if feedback_tween_shield and feedback_tween_shield.is_running():
				feedback_tween_shield.kill()

			feedback_tween_shield = create_tween().set_parallel(true)
			feedback_tween_shield.tween_property(shield_mesh, "scale", Vector3(1.5, 1.5, 1.5), 0.05)
			feedback_tween_shield.tween_property(shield_material, "emission", Color(2.0, 1.7, 0.5), 0.1)
			feedback_tween_shield.tween_property(shield_material, "albedo_color", Color("#e5d41de3") , 0.1)
			feedback_tween_shield.chain().tween_property(shield_mesh, "scale", Vector3.ONE, 0.15)
			feedback_tween_shield.tween_property(shield_material, "emission", Color.BLACK, 0.2)
			feedback_tween_shield.tween_property(shield_material, "albedo_color", shield_base_color, 0.15)
			
		FeedbackType.BLOCKED:
			if feedback_tween_shield and feedback_tween_shield.is_running():
				feedback_tween_shield.kill()

			feedback_tween_shield = create_tween().set_parallel(true)
			feedback_tween_shield.tween_property(shield_mesh, "scale", Vector3(1.3, 1.15, 1.3), 0.05)
			feedback_tween_shield.tween_property(shield_material, "emission", Color.WHITE, 0.1)
			feedback_tween_shield.tween_property(shield_material, "albedo_color", Color("#ffffffe3") , 0.05)
			feedback_tween_shield.chain().tween_property(shield_mesh, "scale", Vector3.ONE, 0.15)
			feedback_tween_shield.tween_property(shield_material, "emission", Color.BLACK, 0.2)
			feedback_tween_shield.tween_property(shield_material, "albedo_color", shield_base_color, 0.15)

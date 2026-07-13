extends StaticBody3D

enum State {IDLE, BLOCK}

@onready var label_health = $Label3D_health
@onready var shield = $MeshInstance3D_Shield
var health = 10000
var current_state
var current_time_in_state = 0.0
var max_time_in_state_state = 3
var max_parry_time = 0.3

var idle_shield_rotation
var idle_shield_position
var block_shield_rotation
var block_shield_position
var shield_tween

func _ready():
	label_health.text = str(health)
	block_shield_rotation = shield.rotation
	block_shield_position = shield.position
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
	if current_time_in_state >= max_time_in_state_state:
		_change_state(State.BLOCK)

func _handle_block_state(delta):
	current_time_in_state += delta
	if current_time_in_state >= max_time_in_state_state:
		_change_state(State.IDLE)

func _change_state(new_state):
	current_state = new_state
	if shield_tween and shield_tween.is_running(): 
		shield_tween.kill()

	shield_tween = create_tween().set_parallel(true)
	match new_state:
		State.IDLE:
			current_time_in_state = 0
			shield_tween.tween_property(shield, "rotation", idle_shield_rotation, 0.3)
			shield_tween.tween_property(shield, "position", idle_shield_position, 0.3) 
		State.BLOCK:
			current_time_in_state = 0
			shield_tween.tween_property(shield, "rotation", block_shield_rotation, 0.3)
			shield_tween.tween_property(shield, "position", block_shield_position, 0.3)

func take_damage(damage, from_position = null, holder = null):
	if current_state == State.BLOCK and from_position != null:
		var vector_to_attack = (from_position - global_position)
		vector_to_attack.y = 0 
		var vector_forward = -global_transform.basis.z
		if vector_forward.angle_to(vector_to_attack) < deg_to_rad(80):
			if current_time_in_state <= max_parry_time and holder != null:
				_disarm.call_deferred(holder,vector_to_attack)
			return
			
	health -= damage
	label_health.text = str(health)


func _disarm(holder, vector_to_attack):
	var w = holder.weapon
	holder.drop_weapon()
	w.apply_central_impulse((vector_to_attack.normalized() + Vector3.UP) * 5)

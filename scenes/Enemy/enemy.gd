extends CharacterBody3D

enum State { PATROL, WATCH, CHASE, ATTACK }

const DETECTION_RANGE = 30
const FOV = 120
const MEMORY_TIME = 4
const SPEED = 2
const CHASE_SPEED = 4

@export var health: int = 100
@export var patrol_route: Node3D
@export var wait_time: float = 4.0
@export var attack_cooldown: float = 2.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 20.0

@onready var label_enemy_health = %Label3D_enemy_health
@onready var player = get_tree().get_first_node_in_group("player")
@onready var navigation_agent = $NavigationAgent3D
@onready var waypoints = patrol_route.get_children()
@onready var ray_player_detector = $RayCast3D_player_detector
@onready var right_hand = $Hand_right
@onready var hand_guard_rotation_x = right_hand.rotation.x
@onready var animation_tree = $AnimationTree
@onready var animation_state_machine = animation_tree.get("parameters/playback")
@onready var animation_player = $characterMedium/Root/AnimationPlayer
@onready var punch_animation_length = animation_player.get_animation("enemy/punch").length
@onready var collision_shape = $CollisionShape3D

const CORPSE_PUSH_FORCE = 4.0
const CORPSE_LIFT_FORCE = 3.0
const CORPSE_SPIN_FORCE = 2.0


var current_wait_time = 0
var current_waypoint = 0
var current_memory_time = 0
var current_state = State.PATROL
var has_dealt_damage_this_swing = false
@onready var current_attack_cooldown_time = attack_cooldown

func _ready():
	label_enemy_health.text = str(health)
	
func _physics_process(delta):
	_handle_gravity(delta)
	_handle_state(delta)
	_handle_animation()
	move_and_slide()

func _handle_animation():
	if current_state == State.CHASE:
		animation_state_machine.travel("enemy_run")
			
	elif current_state == State.PATROL:
		animation_state_machine.travel("enemy_run")
			
	elif current_state == State.WATCH:
		animation_state_machine.travel("enemy_idle")

func _handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_state(delta):
	
	# Interruptor: solo los estados "despistados" pueden descubrir al jugador
	if current_state in [State.PATROL, State.WATCH] and _can_see_player():
		_change_state(State.CHASE)
		
	if current_state == State.ATTACK:
		_handle_attack_state(delta)
		
	elif current_state == State.CHASE:
		_handle_chase_state(delta)
		
	elif current_state == State.PATROL:
		_handle_patrol_state()
		
	elif current_state == State.WATCH:
		_handle_watch_state(delta)

func _change_state(new_state):
	current_state = new_state
	match new_state:
		State.WATCH:
			current_wait_time = 0
		State.CHASE:
			current_memory_time = 0
		State.ATTACK:
			current_attack_cooldown_time = attack_cooldown

func _handle_patrol_state():
	var target = waypoints[current_waypoint].global_position
	target.y = global_position.y
	var distance_to_next_waypoint = global_position.distance_to(target)
	if distance_to_next_waypoint < .5:
		_change_state(State.WATCH)
		current_waypoint = (current_waypoint + 1) % waypoints.size()
	else:
		var direction = waypoints[current_waypoint].global_position - global_position
		direction.y = 0
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction)

func _handle_watch_state(delta):		
	if current_wait_time <= wait_time:
		current_wait_time += delta
		velocity.x = 0
		velocity.z = 0
	else:
		_change_state(State.PATROL)

func _handle_chase_state(delta):
	if global_position.distance_to(player.global_position) < attack_range:
		_change_state(State.ATTACK)
		return
		
	if _can_see_player(): 
		current_memory_time = 0
	else:
		current_memory_time += delta
		if current_memory_time >= MEMORY_TIME:
			_change_state(State.PATROL)
			return
			
	navigation_agent.target_position = player.global_position
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	velocity.x = direction.x * CHASE_SPEED
	velocity.z = direction.z * CHASE_SPEED
	look_at(Vector3(global_position.x, global_position.y, global_position.z) + direction)

func _handle_attack_state(delta):
	current_attack_cooldown_time += delta
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	if global_position.distance_to(player.global_position) < attack_range:
		velocity.x = 0
		velocity.z = 0
		if current_attack_cooldown_time > attack_cooldown:
			current_attack_cooldown_time = 0
			has_dealt_damage_this_swing = false
			animation_state_machine.travel("enemy_punch")
		elif not has_dealt_damage_this_swing and current_attack_cooldown_time > punch_animation_length / 2.0:
			has_dealt_damage_this_swing = true
			if global_position.distance_to(player.global_position) < attack_range:
				player.take_damage(attack_damage)
		elif current_attack_cooldown_time > punch_animation_length:
			animation_state_machine.travel("enemy_idle")
	else: 
		_change_state(State.CHASE)

func _can_see_player():
	if global_position.distance_to(player.global_position) > DETECTION_RANGE:
		return false
	else:
		var vector_to_player = (player.global_position - global_position)
		var vector_forward = -global_transform.basis.z
		if vector_forward.angle_to(vector_to_player) >  deg_to_rad(FOV / 2.0):
			return false
		else:
			ray_player_detector.target_position = ray_player_detector.to_local(player.global_position)
			ray_player_detector.force_raycast_update()
			if not ray_player_detector.is_colliding():
				return false
			if ray_player_detector.get_collider().is_in_group("player"):
				return true
			else:
				return false

func take_damage(damage, from_position = null, _holder = null, _allow_parry = false):
	_change_state(State.CHASE)
	health -= damage
	label_enemy_health.text = str(health)
	if health <= 0:
		_die(from_position)
	return true

func _die(from_position):
	set_physics_process(false)
	animation_tree.active = false  # congela la pose actual del esqueleto
	collision_shape.disabled = true

	# Cuerpo rígido "cadáver": una sola cápsula que rueda, sin física por hueso
	var corpse = RigidBody3D.new()
	corpse.collision_layer = 2   # capa propia: los disparos (máscara 9) lo ignoran
	corpse.collision_mask = 9    # colisiona con el mismo suelo que pisaba el enemigo
	corpse.angular_damp = 3.0    # frena el giro para que deje de rodar y se asiente
	corpse.linear_damp = 0.5
	get_parent().add_child(corpse)
	corpse.global_transform = global_transform

	var corpse_collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.7
	corpse_collision.shape = capsule
	corpse_collision.position.y = 0.9   # centra la cápsula a la altura del torso
	corpse.add_child(corpse_collision)

	# Mueve la malla (en su pose de muerte) bajo el cadáver, conservando su transform
	$characterMedium.reparent(corpse)

	# Empujón: hacia el lado contrario de quien disparó, hacia arriba, con giro
	var push_dir = -global_transform.basis.z
	if from_position != null:
		push_dir = (global_position - from_position)
		push_dir.y = 0
		push_dir = push_dir.normalized()
	corpse.apply_impulse(push_dir * CORPSE_PUSH_FORCE + Vector3.UP * CORPSE_LIFT_FORCE)
	corpse.apply_torque_impulse(Vector3(push_dir.z, 0, -push_dir.x) * CORPSE_SPIN_FORCE)

	queue_free()

extends CharacterBody3D

enum State { PATROL, WATCH, CHASE, ATTACK }

const DETECTION_RANGE = 30
const FOV = 120
const MEMORY_TIME = 4
const SPEED = 1
const CHASE_SPEED = 2

@export var health: int = 100
@export var patrol_route: Node3D
@export var wait_time: float = 4.0
@export var attack_cooldown: float = 2.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 20.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var navigation_agent = $NavigationAgent3D
@onready var waypoints = patrol_route.get_children()
@onready var ray_player_detector = $RayCast3D_player_detector
@onready var right_hand = $Hand_right
@onready var hand_guard_rotation_x = right_hand.rotation.x


var current_wait_time = 0
var current_waypoint = 0
var current_memory_time = 0
var current_state = State.PATROL
@onready var current_attack_cooldown_time = attack_cooldown


func _physics_process(delta):
	_handle_gravity(delta)
	_handle_state(delta)
	move_and_slide()

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
	look_at(global_position + direction)

func _handle_attack_state(delta):
	current_attack_cooldown_time += delta
	look_at(player.global_position)
	if global_position.distance_to(player.global_position) < attack_range:
		velocity.x = 0
		velocity.z = 0
		if current_attack_cooldown_time > attack_cooldown:
			current_attack_cooldown_time = 0
			var tween = create_tween()
			# 1: descarga el palo
			tween.tween_property(right_hand, "rotation:x", hand_guard_rotation_x - deg_to_rad(90), 0.1) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)    
			# 2: AHÍ pega      
			tween.tween_callback(func(): 
				if global_position.distance_to(player.global_position) < attack_range:
					player.take_damage(attack_damage)
) 
			# 3: vuelve a guardia
			tween.tween_property(right_hand, "rotation:x", hand_guard_rotation_x, 0.3)  
			
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

func take_damage(damage):
	health -= damage
	
	if health <= 0:
		queue_free()

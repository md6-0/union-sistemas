extends CharacterBody3D

enum State { NORMAL, CLIMBING }

const SPEED = 4.0
const ACCELERATION = 0.6
const SPRINT_SPEED = 6.0
const JUMP_VELOCITY = 3.0

const BOB_FREQUENCY = 15.0
const BOB_FREQUENCY_SPRINT = 25.0
const BOB_AMPLITUDE = 0.02

const MOUSE_SENSITIVITY = 0.003
const JOYSTICK_SENSITIVITY = 0.05

var player_state = State.NORMAL
var bob_time = 0.0
var is_sprinting = false

@onready var camera = $Camera3D
@onready var climbing_sensor = $ClimbingSensor
@onready var ray_interactable = $Camera3D/RayCast3D_interactable
@onready var weapon = $Camera3D/Weapon
@onready var camera_origin_y = camera.position.y

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if player_state == State.NORMAL and velocity.y > 0:
		#nos agarramos solo si el player salta hacia arriba, al caer no se agarrará
		_handle_ledge_detection()
		
	if player_state == State.NORMAL:
		_handle_gravity(delta)
		_handle_movement(delta)
		_handle_interaction()
		_handle_weapon(delta)
		
	move_and_slide()

func _handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_movement(delta):
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	_handle_camera(look_dir.x, look_dir.y, JOYSTICK_SENSITIVITY)
	
	var current_speed
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED
		is_sprinting = true
	else:
		current_speed = SPEED
		is_sprinting = false
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, ACCELERATION)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, ACCELERATION)
			velocity.z = move_toward(velocity.z, 0, ACCELERATION)
	_handle_bob(delta, direction.length() > 0)

func _handle_ledge_detection():
	var sensor_answer = climbing_sensor.is_ledge_available()
	if sensor_answer.available:
		player_state = State.CLIMBING
		velocity = Vector3(0,0,0)
		var tween = create_tween()
		var forward = -global_transform.basis.z
		var new_position = global_position + forward * 1.25
		new_position.y = sensor_answer.height + 0.9
		tween.tween_property(self, "global_position", new_position , 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(func(): player_state = State.NORMAL)

func _handle_camera(look_x: float, look_y: float, sensitivity: float):
	rotate_y(-look_x * sensitivity)
	camera.rotate_x(-look_y * sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _handle_interaction():
	if ray_interactable.is_colliding():
		var collider = ray_interactable.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("interactable") and Input.is_action_just_pressed("interact"):
			collider.interact(camera)

func _handle_weapon(delta):
	if Input.is_action_just_pressed("shoot"):
		weapon.try_shoot(delta)

func _unhandled_input(event):
	if event is InputEventMouseMotion and player_state != State.CLIMBING:
		_handle_camera(event.relative.x, event.relative.y, MOUSE_SENSITIVITY)

func _handle_bob(delta: float, is_moving: bool):
	var frequency
	if is_sprinting:
		frequency = BOB_FREQUENCY_SPRINT
	else:
		frequency = BOB_FREQUENCY
		
	if is_moving and is_on_floor():
		bob_time += delta * frequency
		camera.position.y = (sin(bob_time) * BOB_AMPLITUDE) + camera_origin_y
	else:
		camera.position.y = move_toward(camera.position.y, camera_origin_y, BOB_AMPLITUDE * delta * 4)

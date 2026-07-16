extends CharacterBody3D

enum State { NORMAL, CLIMBING }

const SPEED = 4.0
const ACCELERATION = 0.6
const SPRINT_SPEED = 6.0
const JUMP_VELOCITY = 4.0

const BOB_FREQUENCY = 13.0
const BOB_FREQUENCY_SPRINT = 20.0
const BOB_AMPLITUDE = 0.03
const FALL_GRAVITY_MULTIPLIER = 2.25

const MOUSE_SENSITIVITY = 0.003
const JOYSTICK_SENSITIVITY = 0.05

const COYOTE_TIME = 0.15
var coyote_timer = 0.0

const JUMP_BUFFER_TIME = 0.15
var jump_buffer_timer = 100.0


var player_state = State.NORMAL
var bob_time = 0.0
var is_sprinting = false
var weapon
var footstep_played = false
var was_on_floor = true
var player_fall_speed = 0.0
var camera_landing_tween

# --- sistema de efectos de cámara: cada uno aporta SU offset, se suman una vez por frame ---
var bob_offset = Vector3.ZERO
var landing_offset = Vector3.ZERO
var shake_roll = 0.0
var shake_trauma = 0.0
const SHAKE_DECAY = 1.5
const SHAKE_MAX_ANGLE = 15.0
var shake_time = 0.0
var shake_noise = FastNoiseLite.new()
var climb_offset = Vector3.ZERO   
var climb_roll = 0.0              

@onready var camera = $Camera3D
@onready var climbing_sensor = $ClimbingSensor
@onready var ray_interactable = $Camera3D/RayCast3D_interactable
@onready var audioStreamPlayer_footsteps = $AudioStreamPlayer_footsteps
@onready var audioStreamPlayer_voice = $AudioStreamPlayer_voice
@onready var audioStreamPlayer_voice2 = $AudioStreamPlayer_voice2
@onready var camera_origin_y = camera.position.y
@onready var camera_origin_x = camera.position.x

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	shake_noise.seed = randi()
	shake_noise.frequency = 1.0

func _physics_process(delta):
	
	was_on_floor = is_on_floor()
	player_fall_speed = velocity.y
	
	_handle_coyote_time(delta)
	_handle_jump_buffer(delta)

	if player_state == State.NORMAL and velocity.y > 0:
		#nos agarramos solo si el player salta hacia arriba, al caer no se agarrará
		_handle_ledge_detection()

	if player_state == State.NORMAL:
		_handle_gravity(delta)
		_handle_movement(delta)
		_handle_interaction()
		_handle_weapon()

	move_and_slide()

	if is_on_floor() and not was_on_floor:
		_handle_landing()

	_handle_screen_shake(delta)
	_apply_camera_effects()

func _handle_gravity(delta):
	if not is_on_floor() and velocity.y > 0:
		velocity += get_gravity() * delta
	elif not is_on_floor() and velocity.y <= 0:
		velocity += (get_gravity() * FALL_GRAVITY_MULTIPLIER) * delta

func _handle_movement(delta):
	
	if  jump_buffer_timer < JUMP_BUFFER_TIME and coyote_timer < COYOTE_TIME:
		coyote_timer = COYOTE_TIME
		jump_buffer_timer = JUMP_BUFFER_TIME
		velocity.y = JUMP_VELOCITY
		audioStreamPlayer_voice.pitch_scale = randf_range(0.9, 1.1)
		audioStreamPlayer_voice.play()
	
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.4
		
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

func _handle_jump_buffer(delta):
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.0
	else:
		jump_buffer_timer += delta

func _handle_coyote_time(delta):
	if is_on_floor():
		coyote_timer = 0.0
	else:
		coyote_timer += delta

func _handle_landing():
	if camera_landing_tween and camera_landing_tween.is_running():
		camera_landing_tween.kill()

	if player_fall_speed < -5.5:
		camera_landing_tween = create_tween()
		camera_landing_tween.set_parallel(true)

		var x_offset = randf_range(-.06, +.06)
		var dip_amount = clamp(abs(player_fall_speed) * 0.05, 0.15, 0.6)
		# ojo: el objetivo ahora es "self" (landing_offset), no la cámara directamente
		camera_landing_tween.tween_property(self, "landing_offset:y", -dip_amount, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		camera_landing_tween.tween_property(self, "landing_offset:x", x_offset, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		camera_landing_tween.chain().tween_property(self, "landing_offset:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		camera_landing_tween.tween_property(self, "landing_offset:x", -x_offset, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		camera_landing_tween.chain().tween_property(self, "landing_offset:x", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _handle_screen_shake(delta):
	if shake_trauma > 0.0:
		shake_trauma = max(shake_trauma - SHAKE_DECAY * delta, 0.0)
		shake_time += delta * 30.0
		var shake_amount = shake_trauma * shake_trauma
		var noise_value = shake_noise.get_noise_1d(shake_time)
		shake_roll = deg_to_rad(noise_value * shake_amount * SHAKE_MAX_ANGLE)
	else:
		shake_roll = 0.0

func _apply_camera_effects():
	camera.position = Vector3(camera_origin_x, camera_origin_y, 0) + bob_offset + landing_offset + climb_offset
	camera.rotation.z = shake_roll + climb_roll

func _handle_camera(look_x: float, look_y: float, sensitivity: float):
	rotate_y(-look_x * sensitivity)
	camera.rotate_x(-look_y * sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if weapon != null:
		weapon.apply_look_sway(look_x * sensitivity, look_y * sensitivity)

func _handle_ledge_detection():
	var sensor_answer = climbing_sensor.is_ledge_available()
	if sensor_answer.available:
		player_state = State.CLIMBING
		velocity = Vector3(0,0,0)
		var forward = -global_transform.basis.z
		var new_position = global_position + forward * 1.25
		new_position.y = sensor_answer.height + 0.9
		var tween = create_tween()
		tween.tween_property(self, "global_position", new_position , 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(func(): player_state = State.NORMAL)
		
		var climb_tween = create_tween().set_parallel(true)
		# tirón 1 (0 → 0.5s): ladeo derecha + hundimiento
		climb_tween.tween_property(self, "climb_roll", deg_to_rad(5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		climb_tween.tween_property(self, "climb_offset:y", -0.15, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# tirón 2 (0.5 → 1.0s): cruza al lado contrario, el cuerpo ya sube
		climb_tween.chain().tween_property(self, "climb_roll", deg_to_rad(-5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		climb_tween.tween_property(self, "climb_offset:y", -0.05, 0.5)
		# coronar (1.0 → 1.5s): todo a cero con asentamiento
		climb_tween.chain().tween_property(self, "climb_roll", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		climb_tween.tween_property(self, "climb_offset:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		audioStreamPlayer_voice2.pitch_scale = randf_range(0.7, .9)
		audioStreamPlayer_voice2.play()

func _handle_interaction():
	if ray_interactable.is_colliding() and Input.is_action_just_pressed("interact"):
		var collider = ray_interactable.get_collider()
		if collider.is_in_group("weapon"):
			if weapon != null:
				weapon.drop()
			collider.pick_up(camera, self)
			weapon = collider
		elif collider.is_in_group("interactable"):
			collider.interact(camera)
	if Input.is_action_just_pressed("drop"):
		drop_weapon()
	
func _handle_weapon():
	if Input.is_action_just_pressed("attack") and weapon != null:
		weapon.try_attack()

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
		bob_offset.y = sin(bob_time) * BOB_AMPLITUDE
		var bob = sin(bob_time)
		if bob < -0.9 and not footstep_played:
			footstep_played = true
			audioStreamPlayer_footsteps.pitch_scale = randf_range(0.8, 1.2)
			audioStreamPlayer_footsteps.play()
		elif bob > 0.9 :
			footstep_played = false
	else:
		bob_offset.y = move_toward(bob_offset.y, 0.0, BOB_AMPLITUDE * delta * 4)

# Public functions
func take_damage(damage):
	GameManager.player_health -= damage
	add_trauma(1)
	if GameManager.player_health <= 0:
		GameManager.player_health = 100
		get_tree().reload_current_scene()

func add_trauma(amount):
	shake_trauma = clamp(shake_trauma + amount, 0.0, 1)

func drop_weapon():
	if weapon != null:
		weapon.drop()
		weapon = null

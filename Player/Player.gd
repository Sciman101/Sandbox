extends KinematicBody

const HALF_PI = PI/2

signal finished_rotating(new_rotation)

# Movemement properties
export var move_speed : float
export var sprint_speed : float
export var acceleration : float

export var gravity : float
export var jump_speed : float

# Node reference
onready var animation = $AnimationPlayer
onready var sprite = $Sprite3D
onready var sprint_particles = $SprintParticles
onready var camera = $CameraOrigin/Camera

# Movement properties
var motion : Vector3
var facing = 1 # Are we facing left or right?
var snap_vector = Vector3.ZERO # Used for hitting the ground

var rotating_player : bool = false
var target_angle : float = 0
var mouse_rotation : float

var spawnpoint = Vector3.ZERO # DEBUG

func _ready():
	# temp
	set_process_input(true)

func _physics_process(delta):
	# Debug respawning
	if Input.is_action_just_pressed("respawn") or translation.y < -5:
		respawn()
	
	handle_movement_jumping(delta)
	handle_spinning(delta)

# Handles movement and jumping
func handle_movement_jumping(delta:float):
	# Check if we're on the floor
	var grounded = is_on_floor()
	
	# Get user input
	var raw_input = Vector3(Input.get_axis('left','right'),0,Input.get_axis('up','down')).normalized()
	var sprinting = Input.is_action_pressed("sprint")
	var transformed_input = transform.basis.xform(raw_input)
	
	var moving = raw_input.length_squared() > 0
	
	var spd = move_speed
	# Change speed if sprinting
	if sprinting:
		spd = sprint_speed
		animation.playback_speed = 2
	else:
		animation.playback_speed = 1
	sprint_particles.emitting = sprinting and grounded and moving
	
	# Interpolate movment vector and play animations
	if moving:
		motion.x = move_toward(motion.x,transformed_input.x*spd,acceleration*delta)
		motion.z = move_toward(motion.z,transformed_input.z*spd,acceleration*delta)
		moving = true
		animation.play("Walk")
		if raw_input.x != 0:
			facing = sign(raw_input.x)
	else:
		motion.x = move_toward(motion.x,0,acceleration*delta*10)
		motion.z = move_toward(motion.z,0,acceleration*delta*10)
		animation.play("Idle")
		moving = false
	
	# Rotate to face direction
	sprite.rotation.y = lerp_angle(sprite.rotation.y,-PI if facing==-1 else 0,delta*15)
	
	# Jumping and gravity
	var wants_to_jump = grounded and Input.is_action_just_pressed("jump")
	var just_landed = grounded and snap_vector == Vector3.ZERO
	
	if grounded:
		motion.y = 0
	else:
		animation.play("Fall")
	
	if wants_to_jump:
		motion.y = jump_speed
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN * 0.1
	
	motion.y -= gravity * delta
	# Actually move
	motion = move_and_slide_with_snap(motion,snap_vector,Vector3.UP)

# Handles camera rotation (actually spins the player)
func handle_spinning(delta:float):
	
	if Input.is_action_pressed("rotate_camera"):
		rotating_player = true
		rotate_y(mouse_rotation * -delta)
		# Set target angle to 90 degree increment
		target_angle = snap_to_90deg(rotation.y)
		mouse_rotation = 0
	elif rotating_player:
		if target_angle != rotation.y:
			rotation.y = lerp_angle(rotation.y,target_angle,delta*15)
			if abs(angle_difference(rotation.y,target_angle)) < 0.01:
				rotation.y = target_angle
				rotating_player = false
				emit_signal("finished_rotating",rotation.y)
	else:
		if Input.is_action_just_pressed("rotate_camera_right"):
			rotate_player(1)
		elif Input.is_action_just_pressed("rotate_camera_left"):
			rotate_player(-1)

# Rotate the player a fixed amount
func rotate_player(increment:int):
	rotating_player = true
	target_angle = snap_to_90deg(rotation.y)+HALF_PI*increment

func respawn(point:Vector3=Vector3.ZERO):
	if point != Vector3.ZERO:
		spawnpoint = point
	translation = spawnpoint
	motion = Vector3.ZERO

# Angle helpers
func snap_to_90deg(angle):
	return round(angle/HALF_PI)*HALF_PI

func angle_difference(angle1, angle2):
	var diff = angle2 - angle1
	return diff if abs(diff) < PI else diff + (PI * 2 * -sign(diff))

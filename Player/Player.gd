extends KinematicBody

const HALF_PI = PI/2

signal finished_rotating(new_rotation)

const Placeholder = preload("res://Placeholder.tscn")

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

onready var environment = $"../Environment"

# Movement properties
var motion : Vector3
var facing = 1 # Are we facing left or right?
var snap_vector = Vector3.ZERO # Used for hitting the ground

var rotating_player : bool = false
var target_angle : float = 0
var mouse_rotation : float

var digging = false
var targeted_block_pos

var spawnpoint = Vector3.ZERO # DEBUG

func _ready():
	# temp
	set_process_input(true)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_rotation = event.relative.x
	
	elif event is InputEventMouseButton:
		if event.pressed and (event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT):
			
			# Cast ray
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 100
			
			var directState = PhysicsServer.space_get_direct_state(get_world().get_space())
			var result = directState.intersect_ray(from,to,[],1)
			if result:
				# Are we within distance?
				if not rotating_player and result.position.distance_to(translation) < 2:
					# Dig or build
					if event.button_index == BUTTON_LEFT:
						player_dig(environment.world_to_block(result.position - result.normal * 0.5))
					else:
						player_dig(environment.world_to_block(result.position + result.normal * 0.5))

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
	
	var moving = raw_input.length_squared() > 0 and not digging
	
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
		if not digging: animation.play("Idle")
		moving = false
	
	# Rotate to face direction
	sprite.rotation.y = lerp_angle(sprite.rotation.y,-PI if facing==-1 else 0,delta*15)
	
	# Jumping and gravity
	var wants_to_jump = grounded and Input.is_action_just_pressed("jump") and not digging
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

func player_dig(blockPos:Vector3):
	# Snap our own position to the grid
	var playerPos = Vector3()
	playerPos.x = round(translation.x)
	playerPos.y = round(translation.y+0.5)
	playerPos.z = round(translation.z)
	
	# Figure out the difference to the block
	var diff = blockPos - playerPos
	# Are we within range to break?
	if diff.y == 0 and abs(diff.x) < 2 and abs(diff.y) < 2:
		# Do we need to turn?
		var d = transform.basis.xform(diff).dot(Vector3.FORWARD)
		digging = true
		targeted_block_pos = blockPos
		animation.play("Dig")
		if abs(d) > 0.9:
			facing = sign(d)
			rotate_player(2 if d == -1 else 1)
			yield(self,'finished_rotating')
		# Remove
		yield(animation,'animation_finished')
		digging = false

func _actually_dig():
	environment.remove_block(targeted_block_pos)

func player_build(blockPos:Vector3):
	pass

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

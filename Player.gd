extends KinematicBody

export var move_speed : float
export var sprint_speed : float
export var dash_speed : float
export var acceleration : float
export var gravity : float
export var jump_speed : float

export var progress_bar_path : NodePath
export var coords_label_path : NodePath

onready var animation = $AnimationPlayer
onready var sprite = $Sprite3D
onready var sprint_particles = $SprintParticles
onready var camera = $CameraOrigin/Camera
onready var cursor = $Cursor

var motion : Vector3
var moving = false
var facing = 1
var snap_vector = Vector3.ZERO

var spawnpoint = Vector3.ZERO

var stamina = 1
var exausted = false
var stamina_bar : ProgressBar
var coords_label : Label

var selected_space : Vector3

func _ready():
	stamina_bar = get_node(progress_bar_path)
	coords_label = get_node(coords_label_path)
	set_process_input(true)

func _input(event):
	if event is InputEventMouseMotion:
		# Cast ray
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 100
		
		var directState = PhysicsServer.space_get_direct_state(get_world().get_space())
		var result = directState.intersect_ray(from,to,[],1)
		if result:
			# Figure out the grid cell
			var pos = result.position - result.normal * 0.5
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			pos.z = round(pos.z)
			selected_space = pos - Vector3(1,0,1)
			coords_label.text = "Selected space: " + str(selected_space)
			cursor.global_transform.origin = pos-Vector3.UP*0.5
	
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			get_node("../Environment").remove_block(selected_space)

func _physics_process(delta):
	
	var grounded = is_on_floor()
	
	if Input.is_action_just_pressed("respawn"):
		respawn()
	
	var spd = move_speed
	# Get user input
	var input = Vector2(Input.get_axis('left','right'),Input.get_axis('up','down')).normalized()
	var sprinting = Input.is_action_pressed("sprint") and not exausted
	var moving = input.length_squared() > 0
	
	if not grounded and Input.is_action_just_pressed("sprint"):
		spd = dash_speed
		stamina -= 0.1
	
	# Handle sprinting
	elif sprinting:
		spd = sprint_speed
		animation.playback_speed = 2
		stamina -= delta * 0.25
		if stamina <= 0:
			exausted = true
			stamina_bar.modulate = Color.red
	else:
		animation.playback_speed = 1
		stamina += delta * 0.2
		if stamina >= 1 and exausted:
			exausted = false
			stamina_bar.modulate = Color.white
	
	stamina = clamp(stamina,0,1)
	sprint_particles.emitting = sprinting and grounded and moving
	stamina_bar.value = stamina
	
	if moving:
		motion.x = move_toward(motion.x,input.x*spd,acceleration*delta)
		motion.z = move_toward(motion.z,input.y*spd,acceleration*delta)
		moving = true
		animation.play("Walk")
		if input.x != 0:
			facing = sign(input.x)
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
	
	motion = move_and_slide_with_snap(motion,snap_vector,Vector3.UP)

func respawn(point:Vector3=Vector3.ZERO):
	if point != Vector3.ZERO:
		spawnpoint = point
	translation = spawnpoint
	motion = Vector3.ZERO

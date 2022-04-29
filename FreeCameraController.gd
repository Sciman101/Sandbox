extends Spatial

export var move_speed : float
export var cam_speed : Vector2

onready var camera = $Camera

var mouse_captured = true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(get_process_delta_time()*event.relative.x*-cam_speed.x)
		camera.rotate_x(get_process_delta_time()*event.relative.y*-cam_speed.y)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x,-90,90)
	
	elif event is InputEventKey:
		if mouse_captured and event.pressed and event.scancode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
	
	elif event is InputEventMouseButton:
		if not mouse_captured and event.pressed and event.button_index == BUTTON_LEFT:
			mouse_captured = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	var dir = Input.get_vector("left","right","up","down")
	var updown = Input.get_axis("sprint","jump")
	dir = Vector3(dir.x,0,dir.y)
	dir = camera.global_transform.basis.xform(dir.normalized())
	dir.y = updown
	
	translation += dir * move_speed * delta

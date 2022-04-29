extends Spatial

export var move_speed : float
export var cam_speed : Vector2

onready var camera = $Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(get_process_delta_time()*event.relative.x*-cam_speed.x)
		camera.rotate_x(get_process_delta_time()*event.relative.y*-cam_speed.y)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x,-90,90)


func _process(delta):
	var dir = Input.get_vector("left","right","up","down")
	var updown = Input.get_axis("sprint","jump")
	dir = Vector3(dir.x,updown,dir.y)
	
	translation += transform.basis.xform(dir.normalized()) * move_speed * delta

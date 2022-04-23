extends Spatial

onready var camera = $Camera
onready var poses = [
	$CameraPose1,
	$CameraPose2
]

var currentPose = 0
var targetPose = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_MIDDLE:
				targetPose = 1 - targetPose

func _process(delta):
	if targetPose != currentPose:
		var pose = poses[targetPose]
		camera.translation = lerp(camera.translation,pose.translation,delta*10)
		camera.rotation = lerp(camera.rotation,pose.rotation,delta*10)
		if (camera.translation-pose.translation).length_squared() < 0.1:
			currentPose = targetPose

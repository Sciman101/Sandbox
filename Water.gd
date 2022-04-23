extends MeshInstance


export var player_path : NodePath

var _player

# Called when the node enters the scene tree for the first time.
func _ready():
	_player = get_node(player_path)

func _process(delta):
	translation.x = _player.translation.x
	translation.z = _player.translation.z

extends Spatial

const MAP_WIDTH := 32
const MAP_HEIGHT := 32

onready var Break_Particles = preload("res://Terrain/BreakParticles.tscn")

export var terrain_mat : ShaderMaterial
export var curve : Curve

var bounce = 0
var bouncing = false

# Piece indices
#0 - corner
#2 - wall
#5 - cross top
#7 - inner corner
#8 - top

var ROTATIONS = [
	Basis.IDENTITY.get_orthogonal_index(),
	Basis.IDENTITY.rotated(Vector3.UP,-PI/2).get_orthogonal_index(),
	Basis.IDENTITY.rotated(Vector3.UP,-PI).get_orthogonal_index(),
	Basis.IDENTITY.rotated(Vector3.UP,-PI*1.5).get_orthogonal_index(),
];

enum {
	CORNER_TOP = 0,
	WALL=1,
	WALL_TOP=2,
	CORNER=3,
	CROSS=4,
	CROSS_TOP=5,
	INNER_CORNER=6,
	INNER_CORNER_TOP=7,
	TOP=8
}
enum {
	TR=0,
	BR=1,
	BL=2,
	TL=3,
	POS=0,
	NEG=1
}
const SIDE_TO_TOP = {
	-1:-1,
	WALL:WALL_TOP,
	CORNER:CORNER_TOP,
	INNER_CORNER:INNER_CORNER_TOP,
	CROSS:CROSS_TOP,
	TOP:TOP
}

var PIECES = [
	{idx=-1,rot=TR}, # Nothing
	{idx=CORNER,rot=BR},
	{idx=CORNER,rot=TR},
	{idx=WALL,rot=TR},
	{idx=CORNER,rot=BL},
	{idx=WALL,rot=BR},
	{idx=CROSS,rot=POS},
	{idx=INNER_CORNER,rot=BR},
	{idx=CORNER,rot=TL},
	{idx=CROSS,rot=NEG},
	{idx=WALL,rot=TL},
	{idx=INNER_CORNER,rot=TR},
	{idx=WALL,rot=BL},
	{idx=INNER_CORNER,rot=BL},
	{idx=INNER_CORNER,rot=TL},
	{idx=TOP,rot=POS},
]

onready var gridmap = $GridMap
onready var meshlib = $GridMap.mesh_library

# Heightmap
var heightmap = null
var max_height = 6

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var noise = OpenSimplexNoise.new()
	# Configure
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8
	
	# Setup heightmap
	heightmap = []
	for x in range(MAP_WIDTH):
		heightmap.append([])
		for y in range(MAP_HEIGHT):
			var h = floor(noise.get_noise_2d(x,y)*3+2)
			heightmap[x].append(h)
	
	build_heightmap()
	
	var spawnpoint = Vector3(MAP_WIDTH/2,max_height+2,MAP_HEIGHT/2)
	$"../Player".respawn(spawnpoint)


func _process(delta):
	if bouncing:
		bounce += delta * 2
		terrain_mat.set_shader_param("distort_amt",curve.interpolate(bounce)*0.1)
		if bounce >= 1:
			bounce = 1
			terrain_mat.set_shader_param("distort_amt",0)
			bouncing = false


func get_height(x,y):
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return -2
	else:
		return heightmap[x][y]

func remove_block(pos):
	var old_height = heightmap[pos.x][pos.z]
	var new_height = max(pos.y-2,-2)
	heightmap[pos.x][pos.z] = new_height
	
	# Rebuild the heightmap
	for y in range(new_height,old_height+1):
		if y > -1:
			place_grid_tile(pos.x,y,pos.z)
			place_grid_tile(pos.x,y,pos.z+1)
			place_grid_tile(pos.x+1,y,pos.z)
			place_grid_tile(pos.x+1,y,pos.z+1)
	
	# Handle jiggle animation
	terrain_mat.set_shader_param("distort_point",pos+Vector3(1,-0.5,1))
	bouncing = true
	bounce = 0
	
	# Block breaking particle effects
	var part = Break_Particles.instance()
	part.translation = pos+Vector3(1,-0.5,1)
	part.emitting = true
	add_child(part)

func build_heightmap():
	gridmap.clear()
	for y in range(max_height):
		# Because we're looping over the dual grid, we need to add 1 space
		for x in range(MAP_WIDTH+1):
			for z in range(MAP_HEIGHT+1):
				place_grid_tile(x,y,z)

func place_grid_tile(x,y,z):
	# Get heights at different corners
	var tr = get_height(x,z)
	var tl = get_height(x-1,z)
	var br = get_height(x,z-1)
	var bl = get_height(x-1,z-1)
	# Determine bit mask
	var index = 0
	if tr >= y: index |= 1
	if br >= y: index |= 2
	if tl >= y: index |= 4
	if bl >= y: index |= 8
	# Find a piece using the bit-index
	var piece = PIECES[index]
	var idx = piece.idx
	# shift to the top part if we're at the top
	if tr == y or tl == y or br == y or bl == y: idx = SIDE_TO_TOP[idx]
	
	# Place it
	gridmap.set_cell_item(x,y,z,idx,ROTATIONS[piece.rot])

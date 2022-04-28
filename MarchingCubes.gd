extends MeshInstance
tool

export var grid_size : Vector3 # Number of POINTS, not the blocks
export var cell_size : float = 1
export var surface_level : float

var grid = null

func _ready():
	# We use a 1-d array for performance
	grid = []
	
	var noise = OpenSimplexNoise.new()
	# Uses simplex noise, for now
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				grid.append((noise.get_noise_3d(x,y,z)+1)*0.5)
	
	generate()

# Grid helper methods
func grid_get(x:int,y:int,z:int) -> float:
	return grid[x+z*grid_size.x+y*(grid_size.x*grid_size.z)]
func grid_set(v:float,x:int,y:int,z:int) -> void:
	grid[x+z*grid_size.x+y*(grid_size.x*grid_size.z)] = v
func coord2index(x:int,y:int,z:int) -> int:
	return int(x+z*grid_size.x+y*(grid_size.x*grid_size.z))


# Actually generate a mesh from our grid
func generate():
	# Remove existing mesh if one exists
	if mesh:
		mesh.free()
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Make every individual cell
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				build_cell(x,y,z,st)
	
	# Actually turn into a mesh
	var array_mesh = st.commit()
	mesh = array_mesh


func build_cell(x:int,y:int,z:int,st:SurfaceTool):
	
	# Get cube indicex
	var cube_indices = [
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	]
	
	st.add_vertex(Vector3(x,y,z))
	st.add_vertex(Vector3(x,y+1,z))
	st.add_vertex(Vector3(x,y,z+1))

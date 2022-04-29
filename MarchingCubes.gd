extends MeshInstance
tool

export var grid_size : Vector3 # Number of POINTS, not the blocks
export var cell_size : float = 1
export var surface_level : float

var grid = null

func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# We use a 1-d array for performance
	grid = []
	var scale = 5 * cell_size
	
	var noise = OpenSimplexNoise.new()
	# Uses simplex noise, for now
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				grid.append((noise.get_noise_3d(x*scale,y*scale,z*scale)+1)*0.5)
	
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
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Make every individual cell
	for x in range(grid_size.x-1):
		for y in range(grid_size.y-1):
			for z in range(grid_size.z-1):
				build_cell(x,y,z,st)
	
	# Actually turn into a mesh
	st.generate_normals()
	var array_mesh = st.commit()
	mesh = array_mesh


func build_cell(x:int,y:int,z:int,st:SurfaceTool):
	
	# Get cube indicex
	var cube_indices = [
		coord2index(x,y,z+1),
		coord2index(x+1,y,z+1),
		coord2index(x+1,y,z),
		coord2index(x,y,z),
		coord2index(x,y+1,z+1),
		coord2index(x+1,y+1,z+1),
		coord2index(x+1,y+1,z),
		coord2index(x,y+1,z),
	]
	
	# Build triangulation table index
	var index = 0
	for i in range(8):
		if grid[cube_indices[i]] <= surface_level:
			index |= (1 << i)
	
	if McTables.Edges[index] == 0:
		# This cube is either totally inside or outside the surface, ignore it
		return
	
	var cube_vertices = [
		Vector3(x,y,z+1)*cell_size,
		Vector3(x+1,y,z+1)*cell_size,
		Vector3(x+1,y,z)*cell_size,
		Vector3(x,y,z)*cell_size,
		Vector3(x,y+1,z+1)*cell_size,
		Vector3(x+1,y+1,z+1)*cell_size,
		Vector3(x+1,y+1,z)*cell_size,
		Vector3(x,y+1,z)*cell_size
	]
	
	# Build edge list
	var triangulation = McTables.Triangulation[index]
	for edgeIndex in triangulation:
		if edgeIndex == -1:
			break
		var edges = McTables.VerticesFromEdge[edgeIndex]
		
		#var vertex = (cube_vertices[edges[0]] + cube_vertices[edges[1]]) / 2
		var p1 = cube_vertices[edges[0]]
		var p2 = cube_vertices[edges[1]]
		var v1 = grid[cube_indices[edges[0]]]
		var v2 = grid[cube_indices[edges[1]]]
		var vertex = p1+(((surface_level-v1)*(p2-p1))/(v2-v1))
		
		st.add_vertex(vertex)

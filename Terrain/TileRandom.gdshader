shader_type spatial;

uniform sampler2D tiles : hint_albedo;
uniform float tile_count;

float rand(vec3 value) {
	vec3 smallVal = sin(value);
	float random = dot(smallVal,vec3(12.9898, 78.233, 37.719));
	random = fract(sin(random)*143758.5453);
	return random;
}

void fragment() {
	vec3 worldVertex = (CAMERA_MATRIX * vec4(VERTEX,1.0)).rgb;
	// Convert world coords to chunky values
	vec3 tilePos = floor(worldVertex);
	vec2 tileUv = (worldVertex - tilePos).xz;
	tileUv.x /= tile_count;
	
	// Get tile index
	float index = floor(rand(tilePos)*tile_count)/tile_count;
	
	ALBEDO = texture(tiles,vec2(tileUv.x+index,tileUv.y)).rgb;
	//ALBEDO = vec3(rand(worldVertex));
}
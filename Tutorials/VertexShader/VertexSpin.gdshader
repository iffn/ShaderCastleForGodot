shader_type spatial;

void vertex() {
	vec2 offset = VERTEX.xz;
	vec2 sinCosTime = vec2(sin(TIME), cos(TIME));
	
	// Modifying individual components of the vertex positions to implement the spin
	VERTEX.x = offset.x * sinCosTime.y + offset.y * sinCosTime.x;
	VERTEX.z = -offset.x * sinCosTime.x + offset.y * sinCosTime.y;
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
}

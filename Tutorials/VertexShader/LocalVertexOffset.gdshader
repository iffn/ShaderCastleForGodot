shader_type spatial;

void vertex() {
	VERTEX *= sin(TIME) * 0.5 + 0.5; // Modifiying the existing vertex position
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
}

shader_type spatial;

varying vec3 normals;

void vertex() {
	normals = NORMAL;
}

void fragment() {
	ALBEDO = normals;
}
shader_type spatial;

void vertex() {
	
}

void fragment() {
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	ALBEDO = world_normal;
}
shader_type spatial;

render_mode cull_disabled, unshaded;

void vertex() {
	vec3 uv_pos = vec3(UV, 0.0) - 0.5;
	VERTEX = mix(VERTEX, uv_pos, sin(TIME) * 0.5 + 0.5);
}

void fragment() {
	ALBEDO = vec3(UV, 0.0);
}
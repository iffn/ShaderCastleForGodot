shader_type spatial;

render_mode cull_disabled;

uniform vec3 albedo : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = albedo;
}

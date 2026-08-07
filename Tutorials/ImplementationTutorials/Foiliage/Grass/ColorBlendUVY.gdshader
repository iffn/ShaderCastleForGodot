shader_type spatial;

render_mode cull_disabled;

uniform vec3 bottom : source_color;
uniform vec3 top : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = mix(bottom, top, UV.y);
}

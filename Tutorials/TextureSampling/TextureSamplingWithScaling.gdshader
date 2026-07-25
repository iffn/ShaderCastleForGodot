shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo : source_color; // Assignable texture in the inspector
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

void vertex() {
	
}

void fragment() {
	vec2 modified_uv = UV * uv_scale + uv_offset;
	ALBEDO = texture(albedo, UV).rgb; // Looking up the color of the texture using the UV maps
}

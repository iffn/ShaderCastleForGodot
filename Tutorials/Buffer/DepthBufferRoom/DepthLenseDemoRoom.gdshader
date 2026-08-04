shader_type spatial;
render_mode unshaded; // Disables 3D lighting so the screen texture displays as-is

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	
	ALBEDO = vec3(depth * 1.0);
}
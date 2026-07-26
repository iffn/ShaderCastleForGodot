shader_type spatial;
render_mode unshaded; // Disables 3D lighting so the screen texture displays as-is

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
}
shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
}
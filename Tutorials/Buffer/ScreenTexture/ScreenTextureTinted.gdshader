shader_type spatial;
render_mode unshaded; // Disables 3D lighting so the screen texture displays as-is

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec3 color_tint : source_color;

void vertex() {
	
}

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	ALBEDO = screen * color_tint;
}
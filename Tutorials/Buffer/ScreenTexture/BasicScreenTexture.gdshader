shader_type spatial;
render_mode unshaded; // Disables 3D lighting so the screen texture displays as-is

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	float aspect_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; // Calculate the viewport aspect ratio (width / height)
	VERTEX.x *= aspect_ratio; // Scale the quad's X dimensions to match the screen aspect ratio
}

void fragment() {
	
	ALBEDO = texture(screen_texture, UV).rgb; // Sample the captured screen texture mapped to the quad's mesh UVs
}
shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	float aspect_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; // Calculate the viewport aspect ratio (width / height)
	VERTEX.x *= aspect_ratio; // Scale the quad's X dimensions to match the screen aspect ratio
}

void fragment() {
	ALBEDO = texture(depth_texture, UV).rgb; // Sample the captured screen texture mapped to the quad's mesh UVs
}
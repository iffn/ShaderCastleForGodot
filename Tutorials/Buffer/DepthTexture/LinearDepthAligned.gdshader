shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

float linear_depth(float depth_raw, vec2 screen_uv, mat4 inv_projection_matrix) {
	vec4 ndc;
	
	// Handle the Z-coordinate differences between OpenGL and Vulkan/Reverse-Z
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw * 2.0 - 1.0, 1.0);
	#else
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw, 1.0);
	#endif
	
	vec4 view_space_behind = inv_projection_matrix * ndc;
	view_space_behind.xyz /= view_space_behind.w;
	
	return -view_space_behind.z;
}

void vertex() {
	
}

void fragment() {
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	float depth_distance = linear_depth(depth_raw, SCREEN_UV, INV_PROJECTION_MATRIX);
	
	depth_distance = clamp(depth_distance, 0.0, 1.0);
	
	ALBEDO = vec3(depth_distance);
}
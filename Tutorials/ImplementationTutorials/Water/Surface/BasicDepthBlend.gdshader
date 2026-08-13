shader_type spatial;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec3 water_surface_color : source_color;
uniform vec3 water_depth_color : source_color;
uniform float depth_blend = 1.0;

float linear_depth(float depth_raw, vec3 vertex, vec2 screen_uv, mat4 inv_projection_matrix) {
	vec4 ndc;
	
	// Handle the Z-coordinate differences between OpenGL and Vulkan/Reverse-Z
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw * 2.0 - 1.0, 1.0);
	#else
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw, 1.0);
	#endif
	
	vec4 view_space_behind = inv_projection_matrix * ndc;
	view_space_behind.xyz /= view_space_behind.w;
	
	float depth_distance = vertex.z - view_space_behind.z;
	depth_distance = max(0.0, depth_distance); // Ensure non-negative
	
	return depth_distance;
}

void vertex() {
	
}

void fragment() {
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	float depth_distance = linear_depth(depth_raw, VERTEX, SCREEN_UV, INV_PROJECTION_MATRIX);
	ALBEDO = mix(water_surface_color, water_depth_color, depth_distance / depth_blend);
}

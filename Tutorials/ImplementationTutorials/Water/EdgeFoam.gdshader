shader_type spatial;

uniform sampler2D noise_texture; 
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

uniform vec4 water_color : source_color;
uniform vec4 foam_color : source_color;

uniform float noise_scale = 5.0;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.05;
uniform float depth_cutoff : hint_range(0.0, 0.2)  = 0.05;

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
	
	float depth_distance = linear_depth(depth_raw, VERTEX, UV, INV_PROJECTION_MATRIX);
	
	float noise = texture(noise_texture, SCREEN_UV * noise_scale).r - 0.5;
	float edge = step(depth_distance - noise * noise_strength, depth_cutoff);
	vec4 albedo = mix(water_color, foam_color, edge);
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
}
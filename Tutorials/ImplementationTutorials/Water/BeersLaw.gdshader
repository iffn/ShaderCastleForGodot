shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec3 absorption_coefficients = vec3(0.50, 0.08, 0.01);
uniform vec3 water_base_color : source_color;
uniform float scale = 1.0;

float linear_depth(float depth_raw, vec3 vertex, vec2 screen_uv, mat4 inv_projection_matrix) {
	vec4 ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw, 1.0);
	vec4 view_space_behind = inv_projection_matrix * ndc;
	view_space_behind.xyz /= view_space_behind.w;
	
	float depth_distance = vertex.z - view_space_behind.z;
	depth_distance = max(0.0, depth_distance); // Ensure non-negative
	
	return depth_distance;
}

void fragment() {
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	
	float depth_distance = linear_depth(depth_raw, VERTEX, SCREEN_UV, INV_PROJECTION_MATRIX);
	depth_distance *= scale;
	
	vec3 transmittance = exp(-absorption_coefficients * depth_distance);
	
	ALBEDO = mix(water_base_color, screen_color, transmittance);
}
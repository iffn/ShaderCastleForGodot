// Based on https://www.shadertoy.com/view/lsf3WH

shader_type spatial;
render_mode unshaded;

uniform float scale : hint_range(0.1, 64.0) = 8.0;

float hash11(float value) { // Based on bit shifting for hardware consistency
	if (value == -0.0) {
		value = 0.0;
	}

	uint hash_state = floatBitsToUint(value);

	hash_state ^= 0x27D4EB2Du; 
	hash_state = hash_state * 1103515245u + 12345u;
	hash_state ^= (hash_state >> 16u);
	hash_state *= 0x85ebca6bu;
	hash_state ^= (hash_state >> 13u);
	hash_state *= 0xc2b2ae35u;
	hash_state ^= (hash_state >> 16u);

	return float(hash_state & 0x00ffffffu) / float(0x01000000u);
}

// Deterministic 2D vector hash returning a single float [-1.0, 1.0]
float hash21(ivec2 cell_corner) {
	vec2 grid_pos = vec2(cell_corner);
	float raw_hash = hash11(hash11(grid_pos.x) + grid_pos.y);
	return raw_hash * 2.0 - 1.0;
}

float value_noise_01(in vec2 sample_pos) {
	ivec2 cell_index = ivec2(floor(sample_pos));
	vec2 cell_fract = fract(sample_pos);
	
	vec2 blend_weights = cell_fract * cell_fract * (3.0 - 2.0 * cell_fract); // Same as smoothstep

	// Random scalar values assigned to each of the 4 grid corners
	float bottom_left  = hash21(cell_index + ivec2(0, 0));
	float bottom_right = hash21(cell_index + ivec2(1, 0));
	float top_left     = hash21(cell_index + ivec2(0, 1));
	float top_right    = hash21(cell_index + ivec2(1, 1));

	// Bilinear interpolation across X then Y
	float interpolated_x_bottom = mix(bottom_left, bottom_right, blend_weights.x);
	float interpolated_x_top    = mix(top_left, top_right, blend_weights.x);
	float raw_noise = mix(interpolated_x_bottom, interpolated_x_top, blend_weights.y);

	// Remap noise from [-1.0, 1.0] to [0.0, 1.0]
	return raw_noise * 0.5 + 0.5;
}

void fragment() {
	vec2 sample_uv = UV * scale;
	
	float noise = value_noise_01(sample_uv);

	ALBEDO = vec3(noise);
}
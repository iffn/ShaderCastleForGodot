// Based on https://www.shadertoy.com/view/Msf3WH

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

vec2 random_gradient(ivec2 cell_corner) {
	vec2 grid_pos = vec2(cell_corner);
	float raw_hash = hash11(hash11(grid_pos.x) + grid_pos.y);
	float angle = raw_hash * 6.28318530718;
	return vec2(cos(angle), sin(angle));
}

float simplex_noise01(in vec2 sample_pos) {
	// Skewing and unskewing factors for 2D simplex grid
	const float SKEW_FACTOR   = 0.366025404; // (sqrt(3) - 1) / 2
	const float UNSKEW_FACTOR = 0.211324865; // (3 - sqrt(3)) / 6

	// 1. Skew input space to determine which triangular cell we are in
	float skew_offset = (sample_pos.x + sample_pos.y) * SKEW_FACTOR;
	vec2 skewed_grid_index = floor(sample_pos + skew_offset);
	ivec2 cell_index = ivec2(skewed_grid_index);

	// 2. Unskew cell origin back to Euclidean space
	float unskew_offset = float(cell_index.x + cell_index.y) * UNSKEW_FACTOR;
	vec2 cell_origin = vec2(cell_index) - unskew_offset;

	// Vector from cell origin to sample point (First vertex offset)
	vec2 offset_vertex_0 = sample_pos - cell_origin;

	// 3. Determine which simplex triangle we are in (upper or lower)
	// If offset.x > offset.y, middle corner is (1, 0), else (0, 1)
	vec2 middle_vertex_step = (offset_vertex_0.x > offset_vertex_0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);

	// Offsets for the second and third triangle vertices
	vec2 offset_vertex_1 = offset_vertex_0 - middle_vertex_step + UNSKEW_FACTOR;
	vec2 offset_vertex_2 = offset_vertex_0 - 1.0 + 2.0 * UNSKEW_FACTOR;

	// 4. Calculate radial falloff weights for the 3 vertices: max(0, 0.5 - |dist|^2)^4
	vec3 kernel_falloff = max(
		vec3(0.5) - vec3(
			dot(offset_vertex_0, offset_vertex_0),
			dot(offset_vertex_1, offset_vertex_1),
			dot(offset_vertex_2, offset_vertex_2)
		),
		vec3(0.0)
	);

	vec3 kernel_weights = kernel_falloff * kernel_falloff * kernel_falloff * kernel_falloff;

	// 5. Calculate gradient dot products for all 3 corners
	vec3 corner_contributions = vec3(
		dot(offset_vertex_0, random_gradient(cell_index + ivec2(0, 0))),
		dot(offset_vertex_1, random_gradient(cell_index + ivec2(middle_vertex_step))),
		dot(offset_vertex_2, random_gradient(cell_index + ivec2(1, 1)))
	);

	// 6. Scale total sum to fit roughly [-1.0, 1.0] range
	float raw_noise = 70.0 * dot(kernel_weights, corner_contributions);

	// Remap noise from [-1.0, 1.0] to [0.0, 1.0]
	return clamp(raw_noise * 0.5 + 0.5, 0.0, 1.0);
}

void fragment() {
	vec2 sample_uv = UV * scale;

	float noise = simplex_noise01(sample_uv);

	ALBEDO = vec3(noise);
}
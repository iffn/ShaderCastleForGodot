shader_type spatial;

uniform vec3 albedo : source_color;
uniform float noise_scale : hint_range(0.01, 2.0) = 0.3;
uniform float displacement_strength : hint_range(0.0, 0.1) = 0.05;

uint hash_ivec3(ivec3 cell_corner) {
	uint hash_state = uint(cell_corner.x) * 0x27D4EB2Du + 
	                 uint(cell_corner.y) * 0x85ebca6bu + 
	                 uint(cell_corner.z) * 0x11035152u;

	hash_state ^= (hash_state >> 16u);
	hash_state *= 0x11035152u;
	hash_state ^= (hash_state >> 13u);
	hash_state *= 0xc2b2ae35u;
	hash_state ^= (hash_state >> 16u);

	return hash_state;
}

// Extracts 3D offset vector [-1.0, 1.0] from a SINGLE hash call
vec3 random_offset_3d(ivec3 cell_corner) {
	uint h = hash_ivec3(cell_corner);

	// Extract 10 bits for X, 10 bits for Y, 10 bits for Z (0x3FF = 1023)
	float rx = float(h & 0x3FFu) / 1023.0;
	float ry = float((h >> 10u) & 0x3FFu) / 1023.0;
	float rz = float((h >> 20u) & 0x3FFu) / 1023.0;

	// Remap from [0.0, 1.0] to [-1.0, 1.0]
	return vec3(rx, ry, rz) * 2.0 - 1.0;
}

// 3D Value Noise evaluating and blending the 8 surrounding cube corners
vec3 value_noise_3d_offset(vec3 sample_pos) {
	ivec3 cell_index = ivec3(floor(sample_pos));
	vec3 cell_fract = fract(sample_pos);
	
	// Smooth Hermite interpolant across 3 axes
	vec3 blend_weights = cell_fract * cell_fract * (3.0 - 2.0 * cell_fract);

	// Fetch random 3D vectors assigned to all 8 corners (1 hash call each)
	vec3 corner_000 = random_offset_3d(cell_index + ivec3(0, 0, 0));
	vec3 corner_100 = random_offset_3d(cell_index + ivec3(1, 0, 0));
	vec3 corner_010 = random_offset_3d(cell_index + ivec3(0, 1, 0));
	vec3 corner_110 = random_offset_3d(cell_index + ivec3(1, 1, 0));
	
	vec3 corner_001 = random_offset_3d(cell_index + ivec3(0, 0, 1));
	vec3 corner_101 = random_offset_3d(cell_index + ivec3(1, 0, 1));
	vec3 corner_011 = random_offset_3d(cell_index + ivec3(0, 1, 1));
	vec3 corner_111 = random_offset_3d(cell_index + ivec3(1, 1, 1));

	// Trilinear Interpolation
	vec3 mix_x_front_bottom = mix(corner_000, corner_100, blend_weights.x);
	vec3 mix_x_front_top    = mix(corner_010, corner_110, blend_weights.x);
	vec3 mix_x_back_bottom  = mix(corner_001, corner_101, blend_weights.x);
	vec3 mix_x_back_top     = mix(corner_011, corner_111, blend_weights.x);

	vec3 mix_y_front = mix(mix_x_front_bottom, mix_x_front_top, blend_weights.y);
	vec3 mix_y_back  = mix(mix_x_back_bottom,  mix_x_back_top,  blend_weights.y);

	return mix(mix_y_front, mix_y_back, blend_weights.z);
}

void vertex() {
	vec3 sample_position = VERTEX / noise_scale;
	vec3 offset_vector = value_noise_3d_offset(sample_position);
	VERTEX += offset_vector * displacement_strength;
}

void fragment() {
	ALBEDO = albedo;
}

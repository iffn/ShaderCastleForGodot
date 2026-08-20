shader_type spatial;

render_mode cull_disabled;

uniform vec3 bottom : source_color;
uniform vec3 top : source_color;
uniform float wind_sway_frequency = 1.0;
uniform float wind_strength = 0.1;

void vertex() {
	// Transform vertex to world space
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Uniform time-based sway (matching your original wave rhythm)
	float sway = sin(TIME * wind_sway_frequency) * wind_strength;
	
	// Apply wind in a fixed world direction (World X and Z)
	// Only the top of the grass (UV.y) sways, just like before
	float bend = UV.y * UV.y;
	world_pos.x += sway * bend;
	world_pos.z += (sway * 0.7) * bend; // Slight diagonal world drift
	
	// Transform back to local space for the GPU pipeline
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	ALBEDO = mix(bottom, top, UV.y);
}
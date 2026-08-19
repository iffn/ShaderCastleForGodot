shader_type spatial;

uniform vec3 deep_color : source_color = vec3(0.0, 0.2, 0.4);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.5, 0.7);
uniform sampler2D wave_noise_normal : hint_normal;

uniform float wave_scale : hint_range(0.1, 50.0) = 0.1;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.1;
uniform float noise_depth : hint_range(0.1, 50.0) = 3.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 base_uv = world_pos.xz * wave_scale;
	
	vec2 direction_1 = vec2(0.03, 0.05);
	vec2 lookup_1 = base_uv + (TIME * direction_1);
	vec3 noise_1 = texture(wave_noise_normal, lookup_1).rgb;
	
	vec2 direction_2 = vec2(-0.04, 0.02);
	vec2 lookup_2 = base_uv + (TIME * direction_2);
	vec2 distortion = (noise_1.xy * 2.0 - 1.0) * distortion_strength;
	lookup_2 += distortion; 
	vec3 noise_2 = texture(wave_noise_normal, lookup_2).rgb;
	
	NORMAL_MAP = mix(noise_1, noise_2, 0.5);
	NORMAL_MAP_DEPTH = 3.0;
	ROUGHNESS = 0.15;
	
	// Albedo adjustments to make waves visible at all angles
	float height_1 = abs(noise_1.r - 0.5) * 2.0; 
	float height_2 = abs(noise_2.r - 0.5) * 2.0;
	float wave_height = (height_1 + height_2) * 0.5;
	ALBEDO = mix(deep_color, shallow_color, wave_height);
}
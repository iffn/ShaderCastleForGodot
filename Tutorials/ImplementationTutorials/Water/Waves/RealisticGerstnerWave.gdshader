shader_type spatial;

uniform float wavelength : hint_range(0.01, 1.0) = 0.5;
uniform float steepness : hint_range(0.0, 1.0) = 0.5;
uniform float simulation_speed : hint_range(0.0, 2.0) = 1.0;

const float GRAVITY = 9.81;

varying vec3 local_pos;

vec2 gerstner_wave(vec3 pos, float _wavelength, float _steepness, float _simulation_speed) {
	// Wavelength defines spatial frequency (k) safely
	float wave_number = TAU / max(_wavelength, 0.001);
	
	// Amplitude based on wave number and steepness
	float max_amplitude = 1.0 / wave_number;
	float amplitude = max_amplitude * _steepness;

	// Deep-water dispersion frequency: w = sqrt(g * k)
	float angular_frequency = sqrt(GRAVITY * wave_number);

	// Phase angle (setting _speed_scale = 0 safely freezes animation)
	float phase_angle = wave_number * pos.x - (angular_frequency * TIME * _simulation_speed);

	return amplitude * vec2(cos(phase_angle), sin(phase_angle));
}

void vertex() {
	vec2 wave = gerstner_wave(VERTEX, wavelength, steepness, simulation_speed);
	VERTEX.x += wave.x;
	VERTEX.z += wave.y;
	local_pos = VERTEX;
}

void fragment() {
	vec3 albedo_low = vec3(0.0, 0.0, 1.0);
	vec3 albedo_high = vec3(0.5, 0.5, 1.0);
	float lerp = clamp(local_pos.z * 10.0 + 0.5, 0.0, 1.0);
	vec3 albedo = mix(albedo_low, albedo_high, lerp);
	ALBEDO = albedo;
}
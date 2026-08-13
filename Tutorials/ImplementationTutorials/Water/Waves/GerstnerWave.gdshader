shader_type spatial;

uniform float wavelength : hint_range(0.0, 1.0) = 0.5;
uniform float steepness : hint_range(0.0, 	1.0) = 0.5;
uniform float speed : hint_range(0.0, 	1.0) = 0.2;

varying vec3 local_pos;

vec2 gerstner_wave(vec3 vertex, float _wavelength, float _steepness, float _speed) {
	float wave_number = TAU / _wavelength;
	float max_amplitude = 1.0 / wave_number;
	float amplitude = max_amplitude * _steepness;
	float phase_angle = wave_number * (vertex.x - _speed * TIME);
	return amplitude * vec2(cos(phase_angle), sin(phase_angle));
}

void vertex() {
	vec2 wave = gerstner_wave(VERTEX, wavelength, steepness, speed);
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

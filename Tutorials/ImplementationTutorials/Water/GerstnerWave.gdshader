shader_type spatial;

uniform float wavelength : hint_range(0.0, 1.0) = 0.5;
uniform float steepness : hint_range(0.0, 	1.0) = 0.5;
uniform float speed : hint_range(0.0, 	1.0) = 0.2;

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
}

void fragment() {
	ALBEDO = vec3(0.0, 0.0, 1.0);
}

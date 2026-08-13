shader_type spatial;

uniform float wavelength = 0.5;
uniform float amplitude = 0.2;
uniform float speed = 0.2;

void vertex() {
	float wave_number = TAU / wavelength;
	float phase_angle = wave_number * (VERTEX.x - speed * TIME);
	
	VERTEX.z += amplitude * sin(phase_angle);
}

void fragment() {
	ALBEDO = vec3(0.0, 0.0, 1.0);
}
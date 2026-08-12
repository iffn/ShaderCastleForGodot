shader_type spatial;

uniform float wavelength : hint_range(0.01, 10.0) = 0.5;
uniform float steepness : hint_range(0.0, 1.0) = 0.5;
uniform float simulation_speed : hint_range(0.0, 5.0) = 1.0; // 1.0 = realistic physical speed, 0.0 = frozen
uniform float heading_deg : hint_range(0.0, 360.0) = 0.0;

const float GRAVITY = 9.81;

varying vec3 local_pos;

vec3 gerstner_wave(
	vec3 pos,
	float _wavelength,
	float _steepness,
	float _simulation_speed,
	float _heading_rad,
	out vec3 tangent,
	out vec3 binormal
) {
	vec2 dir = vec2(cos(_heading_rad), sin(_heading_rad));

	// Wavelength defines spatial frequency (k) safely
	float wave_number = TAU / max(_wavelength, 0.001);
	
	// Amplitude based on wave number and steepness
	float max_amplitude = 1.0 / wave_number;
	float amplitude = max_amplitude * _steepness;

	// Deep-water dispersion frequency: w = sqrt(g * k)
	float angular_frequency = sqrt(GRAVITY * wave_number);

	// Project horizontal position along wave direction
	float pos_along_wave = dot(pos.xz, dir);

	// Phase angle calculated directly using angular frequency
	float phase_angle = wave_number * pos_along_wave - (angular_frequency * TIME * _simulation_speed);

	float sin_p = sin(phase_angle);
	float cos_p = cos(phase_angle);

	// Analytical partial derivatives (d/dx for Tangent, d/dz for Binormal)
	tangent = vec3(
		1.0 - dir.x * dir.x * _steepness * sin_p,
		dir.x * _steepness * cos_p,
		-dir.x * dir.y * _steepness * sin_p
	);

	binormal = vec3(
		-dir.x * dir.y * _steepness * sin_p,
		dir.y * _steepness * cos_p,
		1.0 - dir.y * dir.y * _steepness * sin_p
	);

	vec3 displacement;
	displacement.xz = dir * (amplitude * cos_p); // Horizontal crest pinching
	displacement.y = amplitude * sin_p;          // Vertical wave elevation
	return displacement;
}

void vertex() {
	float heading_rad = radians(heading_deg);

	vec3 local_tangent;
	vec3 local_binormal;

	VERTEX += gerstner_wave(
		VERTEX,
		wavelength,
		steepness,
		simulation_speed,
		heading_rad,
		local_tangent,
		local_binormal
	);

	TANGENT = normalize(local_tangent);
	BINORMAL = normalize(local_binormal);
	NORMAL = normalize(cross(local_binormal, local_tangent));

	local_pos = VERTEX;
}

void fragment() {
	vec3 albedo_low = vec3(0.0, 0.0, 1.0);
	vec3 albedo_high = vec3(0.5, 0.5, 1.0);
	float lerp = clamp(local_pos.y * 10.0 + 0.5, 0.0, 1.0);
	vec3 albedo = mix(albedo_low, albedo_high, lerp);

	ALBEDO = albedo;
	ROUGHNESS = 0.1;
	METALLIC = 0.0;
}
shader_type spatial;

uniform float wave_scale : hint_range(0.01, 10.0) = 1.0;
uniform float simulation_speed : hint_range(0.0, 5.0) = 1.0;
uniform float gravity : hint_range(0.1, 20.0) = 9.81;

varying vec3 local_pos;

const int WAVE_COUNT = 4;

const float WAVELENGTHS[4] = float[](25.0, 12.0, 6.0, 2.5);
const float STEEPNESSES[4] = float[](0.25, 0.20, 0.15, 0.08);
const float HEADINGS[4]   = float[](0.00, 0.42, -0.61, 1.20);

vec3 gerstner_wave(
	vec3 pos,
	float wavelength,
	float steepness,
	float heading_rad,
	float _gravity,
	float _sim_speed,
	inout vec3 tangent,
	inout vec3 binormal
) {
	vec2 dir = vec2(cos(heading_rad), sin(heading_rad));
	float safe_wavelength = max(wavelength, 0.01);

	float wave_number = (2.0 * PI) / safe_wavelength;
	float frequency = sqrt(_gravity * wave_number);

	float max_amplitude = 1.0 / wave_number;
	float amplitude = max_amplitude * steepness;

	float pos_along_wave = dot(pos.xz, dir);
	float phase_angle = wave_number * pos_along_wave - (frequency * TIME * _sim_speed);

	float sin_p = sin(phase_angle);
	float cos_p = cos(phase_angle);

	// Accumulate partial derivatives (d/dx for Tangent, d/dz for Binormal)
	tangent.x -= dir.x * dir.x * steepness * sin_p;
	tangent.y += dir.x * steepness * cos_p;
	tangent.z -= dir.x * dir.y * steepness * sin_p;

	binormal.x -= dir.x * dir.y * steepness * sin_p;
	binormal.y += dir.y * steepness * cos_p;
	binormal.z -= dir.y * dir.y * steepness * sin_p;

	vec3 displacement;
	displacement.xz = dir * (amplitude * cos_p);
	displacement.y = amplitude * sin_p;
	return displacement;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_pos = world_pos / max(wave_scale, 0.001);

	vec3 world_displacement = vec3(0.0);
	vec3 world_tangent = vec3(1.0, 0.0, 0.0);
	vec3 world_binormal = vec3(0.0, 0.0, 1.0);

	for (int i = 0; i < WAVE_COUNT; i++) {
		world_displacement += gerstner_wave(
			sample_pos,
			WAVELENGTHS[i],
			STEEPNESSES[i],
			HEADINGS[i],
			gravity,
			simulation_speed,
			world_tangent,
			world_binormal
		);
	}

	world_displacement *= wave_scale;
	vec3 local_displacement = (inverse(MODEL_MATRIX) * vec4(world_displacement, 0.0)).xyz;

	VERTEX += local_displacement;

	// Calculate surface normal in world space from accumulated vectors
	vec3 world_normal = normalize(cross(world_binormal, world_tangent));

	// Transform normal, tangent, and binormal into local mesh space
	NORMAL = normalize((inverse(MODEL_MATRIX) * vec4(world_normal, 0.0)).xyz);
	TANGENT = normalize((inverse(MODEL_MATRIX) * vec4(world_tangent, 0.0)).xyz);
	BINORMAL = normalize((inverse(MODEL_MATRIX) * vec4(world_binormal, 0.0)).xyz);

	local_pos = VERTEX;
}

void fragment() {
	vec3 albedo_low = vec3(0.02, 0.05, 0.3);
	vec3 albedo_high = vec3(0.2, 0.5, 0.8);
	float lerp = clamp(local_pos.y * 5.0 + 0.5, 0.0, 1.0);
	ALBEDO = mix(albedo_low, albedo_high, lerp);
	ROUGHNESS = 0.1;
	METALLIC = 0.0;
}
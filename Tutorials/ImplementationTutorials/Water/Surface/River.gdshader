shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.05, 0.3, 0.5);
uniform sampler2D wave_noise_normal : hint_normal;

uniform float wave_scale : hint_range(1.0, 20.0) = 8.0;
uniform float base_speed : hint_range(0.0, 5.0) = 1.0;
uniform float ripple_speed_ratio : hint_range(0.0, 5.0) = 1.5;

// Roughness & Calmness Controls
uniform float wave_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.1;
uniform float ripple_blend : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	
}

void fragment() {
	ROUGHNESS = surface_roughness;
	ALBEDO = albedo;
	
	// Flow directed horizontally towards UV.x
	vec2 flow_direction = vec2(1.0, 0.0);
	vec2 scaled_uv = UV * wave_scale;
	
	// Layer 1: Primary Current-Driven Waves
	float speed_main = base_speed;
	vec2 uv_main = scaled_uv + (flow_direction * TIME * speed_main);
	vec3 normal_main = texture(wave_noise_normal, uv_main).rgb * 2.0 - 1.0;
	
	// Layer 2: Surface Micro-Ripples (speed tied directly to base_speed)
	float speed_ripple = base_speed * ripple_speed_ratio;
	vec2 uv_ripple = (scaled_uv * 1.5) + (flow_direction * TIME * speed_ripple);
	vec3 normal_ripple = texture(wave_noise_normal, uv_ripple).rgb * 2.0 - 1.0;
	
	// Blend the micro-ripples into the main current normals based on the ripple_blend slider
	vec2 blended_xy = mix(normal_main.xy, normal_main.xy + normal_ripple.xy, ripple_blend);
	
	// Construct final normal and apply intensity (calmness control)
	vec3 final_normal = normalize(vec3(blended_xy, 1.0 / max(wave_intensity, 0.001)));
	
	NORMAL_MAP = final_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = wave_intensity;
}
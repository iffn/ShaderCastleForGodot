shader_type spatial;
render_mode depth_draw_always;

uniform vec3 albedo : source_color = vec3(0.05, 0.3, 0.5);
uniform vec3 foam_color : source_color = vec3(0.8, 0.9, 1.0);
uniform sampler2D wave_noise_normal : hint_normal;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform float wave_scale : hint_range(1.0, 20.0) = 8.0;
uniform float base_speed : hint_range(0.0, 5.0) = 1.0;
uniform float ripple_speed_ratio : hint_range(0.0, 5.0) = 1.5;

// Roughness & Calmness Controls
uniform float wave_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.1;
uniform float ripple_blend : hint_range(0.0, 1.0) = 0.5;

// Depth & Obstacle Controls
uniform float depth_fade_distance : hint_range(0.1, 5.0) = 1.0;
uniform float depth_falloff_power : hint_range(0.1, 3.0) = 0.4;

// Waterfall Foam Controls
uniform float waterfall_steepness : hint_range(0.0, 1.0) = 0.5; // Threshold for when slopes turn into waterfalls
uniform float waterfall_foam_amount : hint_range(0.0, 2.0) = 1.0;

float linear_depth(float depth_raw, vec3 vertex, vec2 screen_uv, mat4 inv_projection_matrix) {
	vec4 ndc;
	
	// Handle the Z-coordinate differences between OpenGL and Vulkan/Reverse-Z
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw * 2.0 - 1.0, 1.0);
	#else
		ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw, 1.0);
	#endif
	
	vec4 view_space_behind = inv_projection_matrix * ndc;
	view_space_behind.xyz /= view_space_behind.w;
	
	float depth_distance = vertex.z - view_space_behind.z;
	depth_distance = max(0.0, depth_distance); // Ensure non-negative
	
	return depth_distance;
}

void vertex() {
	
}

void fragment() {
	ROUGHNESS = surface_roughness;
	
	// Sample raw depth and calculate robust linear depth
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float water_depth = linear_depth(depth_raw, VERTEX, SCREEN_UV, INV_PROJECTION_MATRIX);
	
	// Calculate base depth factor and curve it so normals don't die off too early
	float depth_factor = clamp(water_depth / depth_fade_distance, 0.0, 1.0);
	depth_factor = pow(depth_factor, depth_falloff_power);
	
	// Flow and UV Setup (Moving horizontally towards UV.x)
	vec2 flow_direction = vec2(0.0, -1.0);
	vec2 scaled_uv = UV * wave_scale;
	
	// Layer 1: Primary Current-Driven Waves
	float speed_main = base_speed;
	vec2 uv_main = scaled_uv + (flow_direction * TIME * speed_main);
	vec4 tex_main = texture(wave_noise_normal, uv_main);
	vec3 normal_main = tex_main.rgb * 2.0 - 1.0;
	
	// Layer 2: Surface Micro-Ripples
	float speed_ripple = base_speed * ripple_speed_ratio;
	vec2 uv_ripple = (scaled_uv * 1.5) + (flow_direction * TIME * speed_ripple);
	vec4 tex_ripple = texture(wave_noise_normal, uv_ripple);
	vec3 normal_ripple = tex_ripple.rgb * 2.0 - 1.0;
	
	vec2 blended_xy = mix(normal_main.xy, normal_main.xy + normal_ripple.xy, ripple_blend);
	
	// Apply Curved Depth Suppression to Wave Intensity
	float adjusted_intensity = wave_intensity * depth_factor;
	vec3 final_normal = normalize(vec3(blended_xy, 1.0 / max(adjusted_intensity, 0.001)));
	
	NORMAL_MAP = final_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = adjusted_intensity;
	
	// --- World Normal Waterfall Foam Calculation ---
	// Transform fragment normal from view space to world space
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float up_dot = dot(normalize(world_normal), vec3(0.0, 1.0, 0.0));
	
	// Invert up_dot so that steep/vertical slopes yield a high value (0.0 = flat, 1.0 = vertical wall)
	float slope_factor = clamp(1.0 - up_dot, 0.0, 1.0);
	float waterfall_mask = smoothstep(waterfall_steepness - 0.2, waterfall_steepness + 0.2, slope_factor);
	
	// --- Combined Foam Calculation (Obstacle/Shore + Waterfall) ---
	float depth_foam_mask = clamp(1.0 - (water_depth / (depth_fade_distance * 0.4)), 0.0, 1.0);
	float combined_noise = mix(tex_main.r, (tex_main.r + tex_ripple.r) * 0.5, ripple_blend);
	
	// Shore/Obstacle foam
	float edge_foam = smoothstep(0.4, 0.7, depth_foam_mask * combined_noise);
	
	// Waterfall drop foam (driven by vertical slope + noise)
	float fall_foam = smoothstep(0.3, 0.6, waterfall_mask * combined_noise * waterfall_foam_amount);
	
	// Merge both foam types together
	float final_foam = clamp(edge_foam + fall_foam, 0.0, 1.0);
	
	// Apply color and synchronized foam
	ALBEDO = mix(albedo, foam_color, final_foam);
}
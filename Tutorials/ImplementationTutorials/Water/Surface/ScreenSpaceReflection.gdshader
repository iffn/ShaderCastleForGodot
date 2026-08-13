shader_type spatial;
render_mode unshaded;

const float EPSILON = 1e-4;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float ssr_resolution   : hint_range(0.001, 0.2) = 0.2;
uniform float ssr_max_travel   : hint_range(0.0, 200.0) = 30.0;
uniform float ssr_max_diff     : hint_range(0.001, 0.1) = 1.0;

vec2 get_uv_from_view_position(vec3 position_view_space, mat4 proj_m) {
	vec4 position_clip_space = proj_m * vec4(position_view_space, 1.0);
	vec2 position_ndc = position_clip_space.xy / position_clip_space.w;
	return position_ndc * 0.5 + 0.5;
}

vec3 get_view_position_from_uv(vec2 uv, float depth, mat4 inv_proj_m) {
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		vec4 position_ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	#else
		vec4 position_ndc = vec4(uv * 2.0 - 1.0, depth, 1.0);
	#endif
	
	vec4 view_position = inv_proj_m * position_ndc;
	return view_position.xyz / view_position.w;
}

bool is_within_screen_boundaries(vec2 position) {
	return position.x > 0.0 && position.x < 1.0 && position.y > 0.0 && position.y < 1.0;
}

void fragment() {
	vec3 ray_pos = VERTEX;
	vec3 ray_dir = reflect(normalize(VERTEX), NORMAL);

	bool hit = false;
	vec3 hit_color = vec3(0.0);
	vec2 hit_uv = vec2(0.0);

	// Push the ray forward slightly to prevent immediate self-intersection
	ray_pos += ray_dir * EPSILON;

	// Ray march into the scene (Linear Search)
	for (float travel = 0.0; travel < ssr_max_travel; travel += ssr_resolution) {
		ray_pos += ray_dir * ssr_resolution;
		hit_uv = get_uv_from_view_position(ray_pos, PROJECTION_MATRIX);

		if (!is_within_screen_boundaries(hit_uv)) {
			break;
		}

		float depth_raw = texture(depth_texture, hit_uv).r;
		vec3 scene_view_pos = get_view_position_from_uv(hit_uv, depth_raw, INV_PROJECTION_MATRIX);

		float depth_diff = scene_view_pos.z - ray_pos.z;

		// We crossed a surface!
		if (depth_diff >= 0.0 && depth_diff < ssr_max_diff) {
			
			hit_color = texture(screen_texture, hit_uv).rgb;
			hit = true;
			break;
		}
	}

	// Output reflection result
	if (hit) {
		ALBEDO = hit_color;
	} else {
		ALBEDO = vec3(0.3, 0.3, 0.9);
	}
}
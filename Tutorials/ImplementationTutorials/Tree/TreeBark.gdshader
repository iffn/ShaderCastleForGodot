shader_type spatial;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D arm_map : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 v_model_normal;
varying vec3 v_model_tangent;
varying mat3 v_model_to_view;

void vertex() {
	v_model_normal = NORMAL;
	v_model_tangent = normalize(TANGENT.xyz);
	v_model_to_view = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec3 f = normalize(v_model_tangent);
	vec3 n = normalize(v_model_normal);

	// 1. Construct orthogonal basis perpendicular to branch vector
	vec3 up_ref = abs(f.y) > 0.9999 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 local_x = normalize(cross(f, up_ref));
	vec3 local_y = cross(local_x, f);

	// 2. Project surface normal onto cross-section plane
	float x = dot(n, local_x);
	float y = dot(n, local_y);

	// 3. Compute continuous angle around circumference [0.0, 1.0]
	float angle_rad = atan(y, x);
	float angle = (angle_rad + 3.14159265359) / 6.28318530718;

	vec2 uv = vec2(angle, UV.x);

	// 4. Calculate explicit UV derivatives to fix mipmap seams at the 1.0 -> 0.0 wrap point
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	if (dx.x < -0.5) dx.x += 1.0; else if (dx.x > 0.5) dx.x -= 1.0;
	if (dy.x < -0.5) dy.x += 1.0; else if (dy.x > 0.5) dy.x -= 1.0;

	// 5. Sample Albedo
	ALBEDO = textureGrad(albedo_map, uv, dx, dy).rgb;

	// 6. Sample ARM Texture (Red = AO, Green = Roughness, Blue = Metallic)
	vec4 arm_data = textureGrad(arm_map, uv, dx, dy);
	AO = arm_data.r;
	//ROUGHNESS = arm_data.g;
	//METALLIC = arm_data.b;

	// 7. Unpack Normal Map and reorient into Model & View Space
	vec3 map_n = textureGrad(normal_map, uv, dx, dy).rgb * 2.0 - 1.0;
	vec3 model_n = normalize(local_x * map_n.x + f * map_n.y + n * map_n.z);
	
	NORMAL = normalize(v_model_to_view * model_n);
}
shader_type spatial;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D arm_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

/*
Tree mesh data:
- Normal: Standard along the normal of the face
- Tangent: Direction of the branch in local coordinates
- UV.x: How far along the branch. Origin at 0, positive along the branches, negative along the roots. In local units, so more than 1 if longer.
- UV.y: Radius of the branch at the current position.
*/

// Capture model-space vectors purely for stable UV calculation
varying vec3 v_model_normal;
varying vec3 v_model_tangent;

// View-space TBN basis matching our custom UV axes, computed once per vertex
varying vec3 v_view_t; // circumference direction (matches uv.x / angle)
varying vec3 v_view_b; // along-branch direction (matches uv.y / UV.x)
varying vec3 v_view_n; // surface normal

void vertex() {
	v_model_normal = NORMAL;
	v_model_tangent = normalize(TANGENT.xyz);

	vec3 f_local = v_model_tangent;
	vec3 n_local = normalize(v_model_normal);

	vec3 raw_t = cross(n_local, f_local);
	float raw_t_len = length(raw_t);
	vec3 t_local;
	if (raw_t_len < 0.001) {
		vec3 fallback_ref = abs(n_local.y) > 0.9999 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
		t_local = normalize(cross(n_local, fallback_ref));
	} else {
		t_local = raw_t / raw_t_len;
	}

	mat3 mv3 = mat3(MODELVIEW_MATRIX);
	v_view_t = normalize(mv3 * t_local);
	v_view_b = normalize(mv3 * f_local);
	v_view_n = normalize(mv3 * n_local);
}

void fragment() {
	// Wrapping around:
	vec3 f_local = normalize(v_model_tangent);
	vec3 n_local = normalize(v_model_normal);
	vec3 up_ref = abs(f_local.y) > 0.9999 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 local_x = normalize(cross(f_local, up_ref));
	vec3 local_y = cross(local_x, f_local);
	float x = dot(n_local, local_x);
	float y = dot(n_local, local_y);
	float angle_rad = atan(y, x);
	float angle = (angle_rad + 3.14159265359) / 6.28318530718;
	vec2 uv = vec2(angle, UV.x);
	
	// Derivatives for texture sampling, since angle wraps around
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	if (dx.x < -0.5) dx.x += 1.0; else if (dx.x > 0.5) dx.x -= 1.0;
	if (dy.x < -0.5) dy.x += 1.0; else if (dy.x > 0.5) dy.x -= 1.0;

	// Albedo
	ALBEDO = textureGrad(albedo_map, uv, dx, dy).rgb;

	// Normal map:
	vec3 n_sample = textureGrad(normal_map, uv, dx, dy).rgb * 2.0 - 1.0;
	n_sample.y = -n_sample.y; // Flipping somehow needed
	n_sample.z = sqrt(max(0.0, 1.0 - dot(n_sample.xy, n_sample.xy)));

	vec3 T = normalize(v_view_t);
	vec3 B = normalize(v_view_b);
	vec3 N = normalize(v_view_n);

	NORMAL = normalize(T * n_sample.x + B * n_sample.y + N * n_sample.z);
	
	// ARM map:
	vec3 arm_data = textureGrad(arm_map, uv, dx, dy).rgb;
	AO = arm_data.x;
	ROUGHNESS = arm_data.y;
	METALLIC = arm_data.z;
}
shader_type spatial;

uniform sampler2D topMap : source_color;
uniform sampler2D cliffMap : source_color;
uniform float transition : hint_range(0.0, 1.0) = 0.717;
uniform float shaprness : hint_range(1.0, 64.0) = 2.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

vec3 triplanar_color(sampler2D lookup_texture, vec3 pos, vec3 normal, float sharpness_val) {
	vec3 weights = pow(abs(normal), vec3(sharpness_val));
	weights /= (weights.x + weights.y + weights.z);

	vec3 direction = sign(normal);

	vec2 uv_x = vec2(pos.z * direction.x, pos.y);
	vec2 uv_y = vec2(pos.x * direction.y, pos.z);
	vec2 uv_z = vec2(pos.x * -direction.z, pos.y);

	vec3 col_x = texture(lookup_texture, uv_x).rgb;
	vec3 col_y = texture(lookup_texture, uv_y).rgb;
	vec3 col_z = texture(lookup_texture, uv_z).rgb;

	return col_x * weights.x + col_y * weights.y + col_z * weights.z;
}

void fragment() {
	vec3 norm = normalize(world_normal);

	vec3 cliff = triplanar_color(cliffMap, world_pos, norm, shaprness);
	
	vec3 top = texture(topMap, world_pos.xz).rgb;

	float mask = smoothstep(transition - 0.05, transition + 0.05, norm.y);
	vec3 albedo = mix(cliff, top, mask);

	ALBEDO = albedo;
}
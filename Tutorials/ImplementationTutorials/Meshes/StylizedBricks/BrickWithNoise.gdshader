shader_type spatial;

uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo : source_color = vec3(1.0);
uniform float normal_strength : hint_range(0.0, 30.0) = 10.0;

float get_height(vec2 uv) {
	float noise = texture(noise_texture, uv).r;
	return 1.0 - noise;
}

void fragment() {
	vec2 texel_size = vec2(1.0) / vec2(textureSize(noise_texture, 0));
	
	float h_center = get_height(UV);
	float h_right  = get_height(UV + vec2(texel_size.x, 0.0));
	float h_top    = get_height(UV + vec2(0.0, texel_size.y));

	float dx = (h_right - h_center) * normal_strength;
	float dy = (h_top - h_center) * normal_strength;

	vec3 tangent_normal = normalize(vec3(-dx, -dy, 1.0));

	// Remap from [-1.0, 1.0] range to [0.0, 1.0] color space
	NORMAL_MAP = tangent_normal * 0.5 + 0.5;

	ALBEDO = albedo * h_center;
	
	ROUGHNESS = 1.0;
}
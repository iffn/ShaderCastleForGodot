shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float scale = 1.0;

void fragment() {
	vec2 sample_uv = UV * scale;

	float noise_value = texture(noise_texture, sample_uv).r;

	ALBEDO = vec3(noise_value);
}
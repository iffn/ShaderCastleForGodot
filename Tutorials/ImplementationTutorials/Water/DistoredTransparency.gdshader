shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4 water_albedo : source_color;

uniform float distortion : hint_range(0.0, 0.01) = 0.002;

uniform sampler2D noise_texture;

void vertex() {
	
}

void fragment() {
	float noise = texture(noise_texture, SCREEN_UV).r;
	vec2 distorted_screen_uv = SCREEN_UV + distortion * vec2(noise - 0.5);
	vec3 screen = texture(screen_texture, distorted_screen_uv).rgb;
	vec3 albedo = mix(screen, water_albedo.rgb, water_albedo.a);
	ALBEDO = albedo.rgb;
}

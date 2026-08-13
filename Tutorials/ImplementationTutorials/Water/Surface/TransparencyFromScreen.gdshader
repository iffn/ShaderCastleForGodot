shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4 water_albedo : source_color;

void vertex() {
	
}

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	vec3 albedo = mix(screen, water_albedo.rgb, water_albedo.a);
	ALBEDO = albedo.rgb;
}

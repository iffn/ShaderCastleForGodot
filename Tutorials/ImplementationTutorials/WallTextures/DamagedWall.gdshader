shader_type spatial;

uniform float threshold : hint_range(0.0, 1.0) = 0.3;
uniform float half_smoothness : hint_range(0.0, 0.2) = 0.05;
uniform float noise_size = 1.0;

uniform sampler2D albedo_map_1 : source_color;
uniform sampler2D normal_map_1 : hint_normal;
uniform sampler2D arm_map_1;

uniform sampler2D albedo_map_2 : source_color;
uniform sampler2D normal_map_2 : hint_normal;
uniform sampler2D arm_map_2;

uniform sampler2D noise_texture;

void vertex() {
	
}

void fragment() {
	float noise = texture(noise_texture, UV / noise_size).r;
	
	noise = smoothstep(threshold - half_smoothness, threshold + half_smoothness, noise);
	
	ALBEDO = mix(texture(albedo_map_1, UV), texture(albedo_map_2, UV), noise).rgb;
	NORMAL_MAP = mix(texture(normal_map_1, UV), texture(normal_map_2, UV), noise).rgb;
	vec3 arm = mix(texture(arm_map_1, UV), texture(arm_map_2, UV), noise).rgb;
	AO = arm.x;
	ROUGHNESS = arm.y;
	METALLIC = arm.z;
}

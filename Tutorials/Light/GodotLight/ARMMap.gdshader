shader_type spatial;

uniform sampler2D albedo_map : source_color;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D arm_map;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(albedo_map, UV).rgb;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	vec3 arm = texture(arm_map, UV).rgb;
	AO = arm.x;
	ROUGHNESS = arm.y;
	METALLIC = arm.z;
}

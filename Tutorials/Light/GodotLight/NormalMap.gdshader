shader_type spatial;

uniform vec3 albedo : source_color;
uniform sampler2D normal_map : hint_normal;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = albedo;
	NORMAL_MAP = texture(normal_map, UV).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

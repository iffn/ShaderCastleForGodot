shader_type spatial;

uniform float red = 1;
uniform float green = 0;
uniform float blue = 0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = vec3(red, green, blue);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

shader_type spatial;
render_mode unshaded;

uniform float red = 1; // Uniforms as input variables for the inspector
uniform float green = 1;
uniform float blue = 0;

void vertex() {
	
}

void fragment() {
	ALBEDO = vec3(red, green, blue); // Using the uniform variables
}

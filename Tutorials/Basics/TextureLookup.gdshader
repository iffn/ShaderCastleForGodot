shader_type spatial;
render_mode unshaded;

uniform sampler2D image : source_color; // Assignable texture in the inspector

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(image, UV).rgb; // Looking up the color of the texture using the UV maps
}

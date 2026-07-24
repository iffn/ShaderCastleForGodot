shader_type spatial;
render_mode unshaded;

uniform sampler2D image : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(image, TIME * 0.2 + UV).rgb; // Using the time variable and adding it to the position
}
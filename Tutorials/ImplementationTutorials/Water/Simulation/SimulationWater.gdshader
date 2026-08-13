shader_type spatial;

uniform sampler2D compute : source_color;

uniform vec3 base_color : source_color;
uniform vec3 peak_color : source_color;

void vertex() {
	
}

void fragment() {
	float height = texture(compute, UV).r;
	
	ALBEDO = mix(base_color, peak_color, height);
}

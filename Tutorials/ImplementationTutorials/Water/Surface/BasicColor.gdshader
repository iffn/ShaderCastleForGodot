shader_type spatial;

uniform vec3 albedo : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = albedo.rgb;
}

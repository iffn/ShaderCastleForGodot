shader_type spatial;

uniform vec4 albedo : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
}

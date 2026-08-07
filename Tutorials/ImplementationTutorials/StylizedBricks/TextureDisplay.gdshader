shader_type spatial;

uniform sampler2D albedo : source_color;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}

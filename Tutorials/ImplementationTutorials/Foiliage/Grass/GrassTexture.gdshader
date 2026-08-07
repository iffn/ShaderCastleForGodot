shader_type spatial;

uniform sampler2D albedo : source_color;
uniform sampler2D normal : hint_normal;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	NORMAL = texture(normal, UV).rgb;
}

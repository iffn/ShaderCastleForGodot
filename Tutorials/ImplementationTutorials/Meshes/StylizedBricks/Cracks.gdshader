shader_type spatial;

uniform sampler2D noise_texture;

uniform vec3 albedo : source_color;

void vertex() {
	
}

void fragment() {
	float noise = texture(noise_texture, UV).r;
	
	float edge = step(0.5, noise) - step(0.53, noise);
	
	ALBEDO = vec3(edge);
}

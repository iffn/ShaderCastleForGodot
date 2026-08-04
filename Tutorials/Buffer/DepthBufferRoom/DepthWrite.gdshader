shader_type spatial;

uniform float depth;
uniform vec4 albedo : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void vertex() {
	
}

void fragment() {
	ALBEDO = albedo.rgb;
	DEPTH = depth;
}
shader_type spatial;

uniform float offset : hint_range(-0.5, 0.5) = -0.2;
uniform vec3 albedo : source_color;

void vertex() {
	VERTEX += offset * NORMAL;
}

void fragment() {
	ALBEDO = albedo;
}

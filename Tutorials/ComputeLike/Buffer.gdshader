shader_type canvas_item;

uniform sampler2D simulation : filter_nearest, source_color;

void fragment() {
	COLOR = texture(simulation, UV).rgba;
}

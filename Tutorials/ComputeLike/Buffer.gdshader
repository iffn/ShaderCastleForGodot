shader_type canvas_item;

uniform sampler2D compute_map : filter_nearest, source_color;

void fragment() {
	COLOR = texture(compute_map, UV).rgba;
}

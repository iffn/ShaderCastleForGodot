shader_type canvas_item;

void fragment() {
	float r = UV.x;
	float g = 1.0 - UV.x;
	float b = 0.5;
	COLOR = vec4(r, g, b, 1.0);
}

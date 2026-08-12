shader_type canvas_item;

uniform sampler2D buffer_map : filter_nearest, source_color;

void fragment() {
	vec3 buffer = texture(buffer_map, UV).rgb; // Ignore alpha channel
	float x_pos = sin(TIME * 2.35) * 0.5 + 0.5;
	float y_pos = cos(TIME * 2.65) * 0.5 + 0.5;
	vec2 pos = vec2(x_pos, y_pos);
	float offset = length(UV - pos);
	
	float paint = step(offset, 0.1);
	
	vec3 paint_color = vec3(sin(TIME), sin(TIME * 0.35), sin(TIME * 0.65)) * 0.5 + vec3(0.5);
	
	vec3 color = mix(buffer, paint_color, paint);
	
	COLOR = vec4(color, 1.0); // Alpha has to be 1.0
}

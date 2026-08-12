shader_type spatial;
render_mode unshaded;

uniform float scale : hint_range(0.1, 100.0) = 5.0;
uniform sampler2D buffer : filter_linear;
uniform float error_scale = 500.0;

void fragment() {
	// Preparation
	vec2 uv = UV;
	vec2 coordinate = (uv * 2.0 - 1.0) * scale;
	
	vec3 black = vec3(0.0, 0.0, 0.0);
	vec3 red = vec3(1.0, 0.0, 0.0);
	vec3 grey = vec3(0.5, 0.5, 0.5);
	vec3 color = vec3(1.0, 1.0, 1.0);
	
	float half_axis_thickness = 0.01 * scale;
	float minor_axis = sign(abs(fract(coordinate.x) - 0.5) - (0.5 - half_axis_thickness)) * 0.5 + 0.5;
	color = mix(color, grey, minor_axis);
	minor_axis = sign(abs(fract(coordinate.y) - 0.5) - (0.5 - half_axis_thickness)) * 0.5 + 0.5;
	color = mix(color, grey, minor_axis);
	float axis = step(-half_axis_thickness, coordinate.x) * step(coordinate.x, half_axis_thickness);
	color = mix(color, black, axis);
	axis = step(-half_axis_thickness, coordinate.y) * step(coordinate.y, half_axis_thickness);
	color = mix(color, black, axis);
	float x = coordinate.x;

	// Function to plot
	vec3 measurement = texture(buffer, vec2(x, 0.5)).rgb;
	float red_offset = (measurement.r - fract(x)) * error_scale;
	float green_offset = (1.0 - measurement.g - fract(x)) * error_scale;
	float blue_offset = (measurement.b - 0.5) * error_scale;
	
	float y = red_offset;

	// Plotting the function
	float plot_function = y - coordinate.y;
	float plot = step(-half_axis_thickness, plot_function) * step(plot_function, half_axis_thickness * 2.0);
	color = mix(color, red, plot);

	ALBEDO = vec3(color);
}
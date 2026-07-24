shader_type spatial;

void vertex() {
	float view_scale_x = length(MODEL_MATRIX[0].xyz);
	float view_scale_y = length(MODEL_MATRIX[1].xyz);
	
	// We replace the X, Y, and Z columns to strip rotation while applying the extracted scale.
	MODELVIEW_MATRIX = mat4(
		vec4(view_scale_x, 0.0, 0.0, 0.0),
		vec4(0.0, view_scale_y, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), 
		MODELVIEW_MATRIX[3] // MODELVIEW_MATRIX[3] holds the viewSpaceCenter translation
	);
	
	VERTEX.z = 0.0;
	
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
}

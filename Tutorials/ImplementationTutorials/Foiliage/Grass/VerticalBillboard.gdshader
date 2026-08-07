shader_type spatial;

uniform vec3 bottom : source_color;
uniform vec3 top : source_color;

void vertex() {
	vec3 world_center = MODEL_MATRIX[3].xyz; // Extract the world-space center of the object
	vec3 camera_pos = INV_VIEW_MATRIX[3].xyz; // Extract the camera's world-space position
	
	// Calculate look direction and flatten the Y axis
	vec3 look_dir = camera_pos - world_center;
	look_dir.y = 0.0;
	look_dir = normalize(look_dir);
	
	vec3 world_up = vec3(0.0, 1.0, 0.0);
	
	vec3 world_right = normalize(cross(world_up, look_dir));
	
	// Extract original scales
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	
	// Rebuild the object's model matrix using our new basis vectors
	mat4 custom_model_matrix = mat4(
		vec4(world_right * scale_x, 0.0),
		vec4(world_up * scale_y, 0.0),
		vec4(look_dir * scale_z, 0.0),
		MODEL_MATRIX[3] // Keep original world position
	);
	
	MODELVIEW_MATRIX = VIEW_MATRIX * custom_model_matrix; // Apply the custom world matrix to the view matrix
	
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX); // Ensure lighting calculates correctly
	
	//VERTEX.z = 0.0; // Flattening the local Z axis.
}

void fragment() {
	ALBEDO = mix(bottom, top, UV.y);
}

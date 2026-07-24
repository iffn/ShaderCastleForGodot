shader_type spatial; // 3D shader
render_mode unshaded; // Writing the colors directly on the screen

void vertex() {
	// Empty means just passing the mesh along
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0); // Setting the red green blue color channels
}

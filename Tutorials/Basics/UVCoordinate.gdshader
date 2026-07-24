shader_type spatial;
render_mode unshaded;

void vertex() {
	
}

void fragment() {
	ALBEDO = vec3(UV.xy, 0.0); // Accessing the UV coordinates of the mesh in the fragment shader
}

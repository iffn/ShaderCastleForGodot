shader_type spatial;

void vertex() {
	
}

void fragment() {
	float distance_to_center = length(UV + vec2(-0.5, -0.5));
	
	ALPHA = clamp(1.0 - distance_to_center * 2.0, 0.0, 1.0);
}

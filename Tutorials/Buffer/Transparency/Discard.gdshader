shader_type spatial;

void vertex() {
	
}

void fragment() {
	float distance_to_center = length(UV + vec2(-0.5, -0.5));
	
	if(distance_to_center > 0.5)
		discard;
}

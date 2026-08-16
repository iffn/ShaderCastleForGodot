shader_type spatial;

void vertex() {
	
}

void fragment() {
	float ndotv = dot(NORMAL, VIEW); // In view space
	float backface = step(ndotv, 0.0);
	vec3 red = vec3(1.0, 0.0, 0.0);
	vec3 white = vec3(1.0, 1.0, 1.0);
	ALBEDO = mix(white, red, backface);
}

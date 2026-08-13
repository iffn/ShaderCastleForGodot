shader_type spatial;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	ALBEDO = vec3(0.0, 0.0, depth);
}
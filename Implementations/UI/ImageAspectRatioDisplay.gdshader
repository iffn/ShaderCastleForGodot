shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo;

void vertex() {
	vec2 tex_size = vec2(textureSize(albedo, 0));
	float aspect_ratio = tex_size.x / tex_size.y;
	VERTEX.x *= aspect_ratio;
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}

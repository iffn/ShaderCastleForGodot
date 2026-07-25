shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo : source_color, filter_linear_mipmap;

uniform float mip_level : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	vec4 col = textureLod(albedo, UV, mip_level); // Sample the texture mip map
	
	ALBEDO = col.rgb;
}
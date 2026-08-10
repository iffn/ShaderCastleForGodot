shader_type spatial;

uniform float offset : hint_range(0.0, 1.0) = 0.2;
uniform sampler2D albedo_map;

void vertex() {
	vec2 uv_center = UV + vec2(-0.5, -0.5);
	vec2 scaled_uv = offset * uv_center;
	vec3 vertex_offset = (TANGENT * scaled_uv.x) + (-BINORMAL * scaled_uv.y);
	VERTEX += vertex_offset;
}

void fragment() {
	vec4 albedo = texture(albedo_map, UV);
	ALBEDO = albedo.rgb;
	if(albedo.a < 0.2)
		discard;
}

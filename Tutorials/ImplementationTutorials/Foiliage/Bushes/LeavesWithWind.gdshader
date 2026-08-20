shader_type spatial;

render_mode cull_disabled;

uniform float offset : hint_range(0.0, 1.0) = 0.2;
uniform sampler2D albedo_map;
uniform float windPosScale = 2.0;
uniform float windFrequency = 5.0;
uniform float windOffset = 0.02;

void vertex() {
	vec2 uv_center = UV + vec2(-0.5, -0.5);
	vec2 scaled_uv = offset * uv_center;
	vec3 vertex_scale_offset = (TANGENT * scaled_uv.x) + (-BINORMAL * scaled_uv.y);
	VERTEX += vertex_scale_offset;
	
	float baseTime = TIME * windFrequency;
	vec3 sample_pos = windPosScale * VERTEX;
	vec3 vertex_wind_offset = vec3(
		sin(baseTime * 1.2 + sample_pos.x),
		sin(baseTime * 0.8 + sample_pos.y),
		sin(baseTime + sample_pos.z)
	);
	vertex_wind_offset *= windOffset;
	VERTEX += vertex_wind_offset;
}

void fragment() {
	vec4 albedo = texture(albedo_map, UV);
	ALBEDO = albedo.rgb;
	if(albedo.a < 0.2)
		discard;
}

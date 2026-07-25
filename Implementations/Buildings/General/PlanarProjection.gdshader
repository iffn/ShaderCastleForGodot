shader_type spatial;

uniform sampler2D albedo_map : source_color;
uniform sampler2D normal_map : source_color;
uniform sampler2D arm_map : source_color;

void get_projection_data(vec3 position, vec3 projection_vector, out vec2 uv, out vec3 tangent, out vec3 bitangent) {
	vec3 normal = normalize(projection_vector);
	vec3 vertical_ref = (abs(normal.y) > 0.999) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);

	vec3 horizontal_axis = normalize(cross(vertical_ref, normal));
	vec3 vertical_axis = cross(normal, horizontal_axis);
	
	float u_raw = dot(position, horizontal_axis);
	float v_raw = dot(position, vertical_axis);
	
	float blend = smoothstep(0.3, 0.6, abs(normal.y));
	
	uv = mix(vec2(u_raw, v_raw), vec2(v_raw, u_raw), blend);
	tangent = mix(horizontal_axis, vertical_axis, blend);
	bitangent = mix(vertical_axis, horizontal_axis, blend);
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	vec2 proj_uv;
	vec3 world_tangent;
	vec3 world_bitangent;
	get_projection_data(world_pos, world_normal, proj_uv, world_tangent, world_bitangent);
	
	UV = proj_uv;
	TANGENT = (VIEW_MATRIX * vec4(world_tangent, 0.0)).xyz;
	BINORMAL = (VIEW_MATRIX * vec4(world_bitangent, 0.0)).xyz;
}

void fragment() {
	ALBEDO = texture(albedo_map, UV).rgb;
	NORMAL = texture(normal_map, UV).rgb;
	vec3 arm = texture(arm_map, UV).rgb;
	AO = arm.x;
	ROUGHNESS = arm.y;
	METALLIC = arm.z;
}

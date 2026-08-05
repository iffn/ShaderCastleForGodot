// Based on: https://godotshaders.com/shader/improved-spom-with-outline-detection-and-self-shadowing/
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

group_uniforms visuals;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_arm : source_color,filter_linear_mipmap,repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float ao_effect : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform sampler2D texture_normal : hint_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16) = 1;

group_uniforms height;
uniform sampler2D texture_heightmap : hint_default_black,filter_linear_mipmap,repeat_enable;
uniform float heightmap_scale = 5;
uniform int heightmap_min_layers : hint_range(8, 64, 1) = 8;
uniform int heightmap_max_layers : hint_range(8, 64, 1) = 32;
uniform int shadow_min_layers : hint_range(8, 64, 1) = 8;
uniform int shadow_max_layers : hint_range(8, 64, 1) = 32;
uniform vec2 heightmap_flip = vec2(1.0);
uniform float min_pom_depth_tilt : hint_range(0.001, 0.5, 0.001) = 0.1;
uniform float reference_plane : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform int heightmap_refinement_steps : hint_range(1, 16, 1) = 3;
/*
*/
group_uniforms uv;
uniform vec2 uv1_scale = vec2(1.0);
uniform vec2 uv1_offset = vec2(0);

varying vec2 base_uv;
varying mat3 tbn;
varying vec3 model_pos;

void vertex() {
    UV = UV * uv1_scale + uv1_offset;
    model_pos = VERTEX;
}

void fragment() {
	base_uv = UV;
	
	vec3 N = normalize(NORMAL);
	vec3 T = normalize(TANGENT) * heightmap_flip.x;
	vec3 B = -normalize(BINORMAL) * heightmap_flip.y;
	mat3 tbn_matrix = mat3(T, B, N);
	vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * tbn_matrix);

	// Parallax Occlusion Mapping (POM) ------------
	float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers),
	abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
	
	float layer_depth = 1.0 / num_layers;
	
	vec2 P = view_dir.xy / max(view_dir.z, min_pom_depth_tilt) * heightmap_scale * 0.01;
	vec2 delta = P / num_layers;
	
	// Reference plane
	vec2 ofs = base_uv + (P * reference_plane);
	
	float depth = 1.0 - texture(texture_heightmap, ofs).r;
	float current_depth = 0.0;

	// Steep parallax
	while (current_depth < depth) {
	    ofs -= delta;
	    depth = 1.0 - texture(texture_heightmap, ofs).r;
	    current_depth += layer_depth;
	}

	// Contact Refinement
	ofs += delta;
	current_depth -= layer_depth;

	vec2 half_delta = delta * 0.5;
	float half_depth = layer_depth * 0.5;

	for (int i = 0; i < heightmap_refinement_steps; i++) {
	    ofs -= half_delta;
	    current_depth += half_depth;
	    depth = 1.0 - texture(texture_heightmap, ofs).r;

	    if (current_depth > depth) {
	        ofs += half_delta;
	        current_depth -= half_depth;
	    }
	    half_delta *= 0.5;
	    half_depth *= 0.5;
	}

	base_uv = ofs;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo_tex.rgb;

	vec3 arm_tex = texture(texture_arm, base_uv).rgb;
	AO = arm_tex.x;
	ROUGHNESS = arm_tex.y;
	METALLIC = arm_tex.z;

	SPECULAR = specular;
	AO_LIGHT_AFFECT = ao_effect;
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	tbn = mat3(TANGENT, -BINORMAL, NORMAL);
}
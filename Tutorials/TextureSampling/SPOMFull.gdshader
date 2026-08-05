// Based on: https://godotshaders.com/shader/improved-spom-with-outline-detection-and-self-shadowing/
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_arm : source_color,filter_linear_mipmap,repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float ao_effect : hint_range(0.0, 1.0, 0.1) = 0.0;

group_uniforms normal_map;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16) = 1;

group_uniforms height;
/**
The heighmap (or displacement) texture (It's used to simulate a fake dispalcement. Also useful to add extra details such as self shadowing, silhouette clipping and curved silhouette clipping).
*/
uniform sampler2D texture_heightmap : hint_default_black,filter_linear_mipmap,repeat_enable;
/**
How deep the fake displacement will be
*/
uniform float heightmap_scale = 5;
/**
The minimum amount of layers (planes) stacked on top of eachother to simulate mesh depth (high values yield better results but can cause slowdown on lower end systems)
*/
uniform int heightmap_min_layers : hint_range(8, 64, 1) = 8;
/**
The maximum amount of layers (planes) stacked on top of eachother to simulate mesh depth (high values yield better results but can cause slowdown on lower end systems)
*/
uniform int heightmap_max_layers : hint_range(8, 64, 1) = 32;
/**
The minimum amount of layers (planes) stacked on top of eachother to simulate shadows (high values yield better results but can cause slowdown on lower end systems)
*/
uniform int shadow_min_layers : hint_range(8, 64, 1) = 8;
/**
The maximum amount of layers (planes) stacked on top of eachother to simulate shadows (high values yield better results but can cause slowdown on lower end systems)
*/
uniform int shadow_max_layers : hint_range(8, 64, 1) = 32;
uniform vec2 heightmap_flip = vec2(1.0);
/**
Dampens texture swimming
*/
uniform float min_pom_depth_tilt : hint_range(0.001, 0.5, 0.001) = 0.1;
/**
Reference height position for 3D effect. 0.0 blocks the top. 0.5 blocks central section (Surface Stable). 1.0 blocks the bottom.
*/
uniform float reference_plane : hint_range(0.0, 1.0, 0.01) = 0.5;
/**
Binary search steps amount for contact refinement.
Values between 3 and 8 should be optimal.
*/
uniform int heightmap_refinement_steps : hint_range(1, 16, 1) = 3;
/**
If enabled, overwrite depth buffer (Z-buffer) using POM's computations.
Allows for the effect to clip with other geometry.
*/
uniform bool write_to_depth = true;

/**
If use_self_shadow is on, the shader will try to compute how shadows casted from higher regions of the height map will cast the shadow onto other, lower regions. This increases graphical fidelity.
*/
uniform bool use_self_shadow = true;

group_uniforms silhouette_clipping;
/**
If use_silhouette_clipping is on, the shader will clip everything that exceeds the UV coordinates (Doesn't allow tiling if this is on obviously). This is helpful to make a plane, or any flat surface have a more realistic, heightmap aligned, edge when viewed from a reasonable angle.bool
*/
uniform bool use_silhouette_clipping = true;
/**
This defines the minimum clipping point of the UV space. Anything below will be clipped. Defaults to Vector2(0,0)
*/
uniform vec2 clip_uv_min = vec2(0.0, 0.0);
/**
This defines the minimum clipping point of the UV space. Anything above will be clipped. Defaults to Vector2(1,1)
*/
uniform vec2 clip_uv_max = vec2(1.0, 1.0);

group_uniforms curved_silhouette;
/**
If use_curved_silhouette is enabled, the shader will try to detect an edge (near the edges of the fragment), which is above the safe threshold, to clip that region and make it transparent.
This is used to simulate displacement on curved surfaces without resorting to tessellation nor vertex displacement. The results are way worse (graphically) than true displacement but it's both greatly better than a normal flat edge AND it's cheaper (computationally) to run with respect to a true displacement shader.
*/
uniform bool use_curved_silhouette = true;
/**
This defines how strong the horizon clipping is. Greater values = greater "erosion" of the edge
*/
uniform float horizon_clip_strength : hint_range(0.0, 4.0, 0.01) = 1.0;
/**
This defines the bias towards horizon height. Increase if the horizon is too flat, decrease if holes appear in the texture
*/
uniform float horizon_height_bias : hint_range(0.0, 1.0, 0.01) = 0.0;
/**
This marks the safe threshold (as if it was an internal region of the fragment which increases with bigger values) that won't clip ANYTHING.
Decrease if there's internal holes, increase if the border is flat.
*/
uniform float horizon_safe_threshold : hint_range(0.0, 0.95, 0.01) = 0.3;
/**
Falloff power.
Higher = flatter, more smooth edge.
Smaller = more harsh, jagged falloff.
*/
uniform float horizon_falloff_power : hint_range(0.5, 8.0, 0.1) = 2.0;
/**
This defines how much physical curvature is required to activate the horizon clipping.
Increase this if you still see artifacts on flat surfaces or slightly beveled edges.
Decrease it to make the effect kick in sooner on large, gentle curves.
*/
uniform float curvature_activation_threshold : hint_range(0.0, 1.0, 0.01) = 0.05;

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

float D_GGX(float cos_theta_m, float alpha) {
    float a = cos_theta_m * alpha;
    float k = alpha / (1.0 - cos_theta_m * cos_theta_m + a * a);
    return k * k * (1.0 / PI);
}

float V_GGX(float NdotL, float NdotV, float alpha) {
    return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

float SchlickFresnel(float u) {
    float m = 1.0 - u;
    float m2 = m * m;
    return m2 * m2 * m;
}

vec3 F0(float mt, float spc, vec3 cl) {
    float dielectric = 0.16 * spc * spc;
    return mix(vec3(dielectric), cl.rgb, vec3(mt));
}

float GetParallaxShadow(vec2 texCoord, vec3 lightDir) {
    if (lightDir.z >= 0.0)
        return 1.0;

    float numLayers = mix(float(shadow_max_layers), float(shadow_min_layers),
        abs(dot(vec3(0.0, 0.0, 1.0), lightDir)));

    vec2 currentTexCoords = texCoord;
    float currentDepthMapValue = 1.0 - texture(texture_heightmap, currentTexCoords).r;
    float currentLayerDepth = currentDepthMapValue;
    float layerDepth = 1.0 / numLayers;
    vec2 P = lightDir.xy / lightDir.z * heightmap_scale * 0.01;
    vec2 deltaTexCoords = P / numLayers;

    while (currentLayerDepth <= currentDepthMapValue && currentLayerDepth > 0.0) {
        currentTexCoords += deltaTexCoords;
        currentDepthMapValue = 1.0 - texture(texture_heightmap, currentTexCoords).r;
        currentLayerDepth -= layerDepth;
    }

    return currentLayerDepth > currentDepthMapValue ? 0.2 : 1.0;
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

	// Pixel depth offset, AKA write to depth
	if (write_to_depth) {
		float local_z_offset = (current_depth - reference_plane) * heightmap_scale * 0.01;
		float view_space_dist = local_z_offset / max(dot(NORMAL, VIEW), 0.0001);
		vec3 offset_vertex = VERTEX - VIEW * view_space_dist;
		vec4 clip_pos = PROJECTION_MATRIX * vec4(offset_vertex, 1.0);
		DEPTH = clip_pos.z / clip_pos.w;
	}
	else {
		DEPTH = FRAGCOORD.z;
	}

	// --------------------------------------------

	// Silhouette Clipping UV (discard when below and above thresholds) ---
	if (use_silhouette_clipping) {
		if (base_uv.x < clip_uv_min.x || base_uv.x > clip_uv_max.x ||
			base_uv.y < clip_uv_min.y || base_uv.y > clip_uv_max.y) {
			discard;
		}
	}
	// --------------------------------------------------------------------

	// CURVED SURFACE HORIZON CLIPPING ------------------------
	//
	// Use posiiton in model space to compute how much the fragment is far from the view axis passing through the center of the mesh. NOTE: This is monotonous from the center of the edge.
	//
	// This works by:
	// 1. Transforming view direction in model space
	// 2. Project model_pos the plane perpendicular to the view
	// 3. the distance of this projection is equal to "distance from silhouette center": 0 when in the middle and mesh_radius on the border
	// CURVED SURFACE HORIZON CLIPPING ------------------------
	if (use_curved_silhouette) {
		float NdotV = abs(dot(NORMAL, VIEW));

		// 1. IL VERO RILEVATORE DI PIANURE: Misuriamo quanto cambia la Normale.
		// Su un piano perfetto, fwidth(NORMAL) è un vettore di zeri (0,0,0).
		// Usiamo length() per ottenere un singolo numero che rappresenta l'entità del cambiamento.
		float normal_change = length(fwidth(NORMAL));

		// 2. Normalizziamo in base alla scala del pixel nel mondo per coerenza a varie distanze
		float pixel_size = length(fwidth(VERTEX));
		float true_curvature = normal_change / max(pixel_size, 0.0001);

		// 3. Maschera di curvatura: 0.0 su superfici piatte, sale a 1.0 su quelle curve.
		// Sfruttiamo il nuovo uniform per controllare la sensibilità.
		float curvature_mask = smoothstep(0.0, curvature_activation_threshold, true_curvature);

		// Calcolo originale del drop-off dell'orizzonte
		float t = clamp(1.0 - NdotV / max(horizon_safe_threshold, 0.001), 0.0, 1.0);

		// 4. Applichiamo la maschera! Se curvature_mask è 0 (piano), horizon_factor diventa 0
		// disattivando completamente il ritaglio.
		float horizon_factor = pow(t, horizon_falloff_power) * curvature_mask;

		float height_threshold = clamp(horizon_factor * horizon_clip_strength, 0.0, 1.0);
		float surface_height = texture(texture_heightmap, base_uv).r - horizon_height_bias;

		if (surface_height < height_threshold) {
			discard;
		}
	}
	// -------------------------------------------------------

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

void light() {
	vec3 L = normalize(LIGHT);
	vec3 N = normalize(NORMAL);
	vec3 V = normalize(VIEW);
	vec3 light_dir = -L * tbn;

	float NdotL = min(dot(N, L), 1.0);
	float cNdotL = max(NdotL, 0.0);
	float NdotV = dot(N, V);
	float cNdotV = max(NdotV, 1e-4);

	vec3 H = normalize(V + L);
	float cLdotH = clamp(dot(L, H), 0.0, 1.0);
	float cNdotH = clamp(dot(N, H), 0.0, 1.0);
	float cLdotH5 = SchlickFresnel(cLdotH);

	float shadow = GetParallaxShadow(base_uv, light_dir);

	float diffuse_brdf_NL = cNdotL * (1.0 / PI);
	float D = D_GGX(cNdotH, ROUGHNESS);
	float G = V_GGX(cNdotL, cNdotV, ROUGHNESS);
	vec3 f0 = F0(METALLIC, specular, ALBEDO);
	float f90 = clamp(dot(f0, vec3(50.0 * 0.33)), METALLIC, 1.0);
	vec3 F = f0 + (f90 - f0) * cLdotH5;
	vec3 specular_brdf_NL = cNdotL * D * F * G;

	if (use_self_shadow)
		DIFFUSE_LIGHT += diffuse_brdf_NL * shadow * LIGHT_COLOR * ATTENUATION;
	else
		DIFFUSE_LIGHT += diffuse_brdf_NL * LIGHT_COLOR * ATTENUATION;

	SPECULAR_LIGHT += specular_brdf_NL * LIGHT_COLOR * SPECULAR_AMOUNT * ATTENUATION;
}

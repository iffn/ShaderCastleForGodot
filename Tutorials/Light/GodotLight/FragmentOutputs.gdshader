shader_type spatial;

uniform vec3 albedo : source_color = vec3(1.0, 0.0, 0.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float ao : hint_range(0.0, 1.0) = 1.0;
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = albedo;
	METALLIC = metallic; // Is or is not metallic. In between only if there are pixels that have both metallic and non-metallic visuals
	ROUGHNESS = roughness; // Microfacet distribution. 0 = aligned, 1 = large difference
	SPECULAR = specular; // Non-energy conserving reflectivity, keep it at 0.5
	AO = ao; // How much ambient light reaches this point. Low for deep down in a narrow gap
	AO_LIGHT_AFFECT = ao_light_affect; // How much occlusion affects direct lights, default 0
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

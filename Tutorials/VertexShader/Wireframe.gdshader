shader_type spatial;

render_mode unshaded;

uniform vec4 modelColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 wireframeColor : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width : hint_range(0.0, 15.) = 1.0;

const vec3 vectors[3] = {
	vec3(1.0, 0.0 ,0.0),
	vec3(0.0, 1.0 ,0.0),
	vec3(0.0, 0.0 ,1.0)
};

varying vec3 barycentricCoordinates;

void vertex()
{
	barycentricCoordinates = vectors[VERTEX_ID % 3];
}

void fragment() {
	vec3 dBaryCoordX = dFdx(barycentricCoordinates);
	vec3 dBaryCoordY = dFdy(barycentricCoordinates);
	vec3 dBaryCoord  = sqrt(dBaryCoordX*dBaryCoordX + dBaryCoordY * dBaryCoordY);

	vec3 remap = smoothstep(
		vec3(0.0),
		dBaryCoord * width,
		barycentricCoordinates
	);
	
	float closestEdge = min(min(remap.x, remap.y), remap.z);

	ALBEDO = mix(wireframeColor, modelColor, closestEdge).xyz;
}
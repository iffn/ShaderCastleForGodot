shader_type canvas_item;

uniform sampler2D buffer_map : filter_nearest, repeat_disable;

uniform float ABSORBTION_LAYER_THICKNESS = 1.0;

float hash11(float value) { // Based on bit shifting for hardware consistency
	if (value == -0.0) {
		value = 0.0;
	}

	uint hash_state = floatBitsToUint(value);

	hash_state ^= 0x27D4EB2Du; 
	hash_state = hash_state * 1103515245u + 12345u;
	hash_state ^= (hash_state >> 16u);
	hash_state *= 0x85ebca6bu;
	hash_state ^= (hash_state >> 13u);
	hash_state *= 0xc2b2ae35u;
	hash_state ^= (hash_state >> 16u);

	return float(hash_state & 0x00ffffffu) / float(0x01000000u);
}

void fragment() {
	// Shader toy parameters
	vec2 tex_size = vec2(textureSize(buffer_map, 0));
	vec2 pixel_size = 1.0 / tex_size;
	vec2 fragCoord = UV * tex_size;
	vec2 iResolution = tex_size;
	float iTime = TIME;
	vec2 uv = UV;
	
	// Pixel offsets
    float du = 1.0 / iResolution.x;
    float dv = 1.0 / iResolution.y;
    
    vec4 center = texture(buffer_map, uv);
    vec4 up    = texture(buffer_map, uv + vec2(0, dv));
    vec4 down  = texture(buffer_map, uv - vec2(0, dv));
    vec4 left  = texture(buffer_map, uv - vec2(du, 0));
    vec4 right = texture(buffer_map, uv + vec2(du, 0));

    float waveSpeed = 0.2; 
    
    float laplacianWeightedSum = up.r + down.r + left.r + right.r - 4.0 * center.r;

    float nextAmplitude = 2.0 * center.r - center.g + waveSpeed * laplacianWeightedSum;

    // New state: New amplitude to R, Current amplitude to G
    vec4 fragColor = vec4(nextAmplitude, center.r, 0.0, 0.0);

    // Rain drops
	float rest = mod(TIME, 0.2);
    if (rest < 0.1) {
        vec2 center = iResolution.xy;
		
		float random_x = hash11(TIME - rest);
		float random_y = hash11(random_x);
		
		center.x *= random_x;
		center.y *= random_y;
        float radiusInPixels = 10.0;
        
        float d = distance(fragCoord, center);
        float val = step(d, radiusInPixels);
        
        fragColor += vec4(val, val, 0.0, 0.0);
    }
	
	fragColor = clamp(fragColor, 0.0, 1.0);
	
	COLOR = vec4(fragColor.rgb, 1.0);
	//COLOR = vec4(.0, .0, .0, 1.0);
}
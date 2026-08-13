shader_type canvas_item;

uniform sampler2D buffer_map : filter_nearest, repeat_disable;

uniform float ABSORBTION_LAYER_THICKNESS = 1.0;

void fragment() {
	// Dynamically calculate resolution and pixel metrics from the texture
	vec2 tex_size = vec2(textureSize(buffer_map, 0));
	vec2 pixel_size = 1.0 / tex_size;
	vec2 fragCoord = UV * tex_size;
	vec2 iResolution = tex_size;
	float iTime = TIME;
	
	float du = pixel_size.x;
	float dv = pixel_size.y;
	
	vec4 centerColor = texture(buffer_map, UV + vec2(du, 0.0));
	vec4 upColor     = texture(buffer_map, UV + vec2(du, dv));
	vec4 downColor   = texture(buffer_map, UV + vec2(du, -dv));
	vec4 leftColor   = texture(buffer_map, UV + vec2(0.0, 0.0));
	vec4 rightColor  = texture(buffer_map, UV + vec2(2.0 * du, 0.0));
	
	float center = centerColor.r;
	float up = upColor.r;
	float down = downColor.r;
	float left = leftColor.r;
	float right = rightColor.r;
	float centerPrev = centerColor.g;

	float waveSpeed = 0.44;
	float waveSpeedSquared = waveSpeed * waveSpeed;
	
	float laplacianWeightedSum = up + down + left + right - 4.0 * center;

	float nextAmplitude = 2.0 * center - centerPrev + waveSpeedSquared * laplacianWeightedSum;
	
	// Edge absorption
	if (fragCoord.x <= ABSORBTION_LAYER_THICKNESS || fragCoord.x >= iResolution.x - ABSORBTION_LAYER_THICKNESS || 
		fragCoord.y <= ABSORBTION_LAYER_THICKNESS || fragCoord.y >= iResolution.y - ABSORBTION_LAYER_THICKNESS) 
	{
		float coeff = (waveSpeed - 1.0) / (waveSpeed + 1.0);
		
		float currentInner;
		if      (fragCoord.x <= ABSORBTION_LAYER_THICKNESS)                  currentInner = right;
		else if (fragCoord.x >= iResolution.x - ABSORBTION_LAYER_THICKNESS) currentInner = left;
		else if (fragCoord.y <= ABSORBTION_LAYER_THICKNESS)                  currentInner = up;
		else                                                                currentInner = down;

		nextAmplitude = currentInner + (nextAmplitude - center) * coeff;
	}
	
	// New state: New amplitude to R, Current amplitude to G
	vec4 fragColor = vec4(nextAmplitude, center, 0.0, 0.0);
	
	// Adding a moving circle
	vec2 circleCenter = vec2(0.9 * iResolution.x, (0.5 + sin(iTime) * 0.3) * iResolution.y);
	float radiusInPixels = 1.0; 

	float d = distance(fragCoord, circleCenter);
	float circle = step(d, radiusInPixels);
	
	fragColor.r += circle;
	fragColor.g += circle;
	
	fragColor = clamp(fragColor, 0.0, 1.0);
	
	COLOR = vec4(fragColor.rgb, 1.0);
	//COLOR = vec4(.0, .0, .0, 1.0);
}
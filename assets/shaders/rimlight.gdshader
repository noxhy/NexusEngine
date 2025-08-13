shader_type canvas_item;

uniform float angle : hint_range(-360.0, 360.0) = 0.0;  // degrees
uniform float distance : hint_range(0.0, 256.0) = 10.0; // pixels
uniform vec4 rimlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // rgba
uniform float threshold : hint_range(0.0, 1.0) = 0.5;   // brightness threshold
uniform float hue: hint_range(-360.0, 360.0, 1.0) = 0.0;
uniform float saturation = 0.0;
uniform float contrast = 0.0;
uniform float brightness = 0.0;

// I used ChatGPT for this im ngl

// helper: perceived brightness
float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 applyHue(vec3 aColor, float aHue) {
    float ang = radians(aHue);
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(ang);
    return aColor * cosAngle + cross(k, aColor) * sin(ang) + k * dot(k, aColor) * (1.0 - cosAngle);
}

vec3 applyHSBCEffect(vec3 color) {
    color = clamp(color + ((brightness) / 255.0), 0.0, 1.0);
    color = applyHue(color, hue);
    color = clamp((color - 0.5) * (1.0 + ((contrast) / 255.0)) + 0.5, 0.0, 1.0);

    vec3 intensity = vec3(dot(color, vec3(0.30980392156, 0.60784313725, 0.08235294117)));
    color = clamp(mix(intensity, color, (1.0 + (saturation / 100.0))), 0.0, 1.0);

    return color;
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	// pixel offset in UV units
	vec2 distance_scaled = vec2(cos(radians(angle)) * TEXTURE_PIXEL_SIZE.x * distance,
	                            sin(radians(angle)) * TEXTURE_PIXEL_SIZE.y * distance);

	vec2 overlap_uv = UV + vec2(distance_scaled.x, -distance_scaled.y);

	float overlap_alpha = 0.0;
	if (overlap_uv.x >= 0.0 && overlap_uv.x <= 1.0 && overlap_uv.y >= 0.0 && overlap_uv.y <= 1.0) {
		overlap_alpha = texture(TEXTURE, overlap_uv).a;
	}

	// only apply rimlight if pixel brightness is above threshold
	float bright = luminance(texture_color.rgb);
	
	vec3 hsv = applyHSBCEffect(texture_color.rgb); 
	texture_color = vec4(hsv * COLOR.a, COLOR.a);
	
	if (bright > threshold) {
		vec3 out_color = mix(rimlight_color.rgb, texture_color.rgb, overlap_alpha * rimlight_color.a);
		COLOR = vec4(out_color * texture_color.a, texture_color.a);
	} else {
		COLOR = texture_color; // no rimlight applied
	}
}

shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform mat4 world_matrix;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;
}

vec3 blend_func(vec3 src, vec3 dst) {
    vec3 blend_result = src;
    if (dst.r <= 0.5) { blend_result.r = (2.0 * src.r * dst.r); } else { blend_result.r = (1.0 - 2.0 * (1.0 - dst.r) * (1.0 - src.r)); }
    if (dst.g <= 0.5) { blend_result.g = (2.0 * src.g * dst.g); } else { blend_result.g = (1.0 - 2.0 * (1.0 - dst.g) * (1.0 - src.g)); }
    if (dst.b <= 0.5) { blend_result.b = (2.0 * src.b * dst.b); } else { blend_result.b = (1.0 - 2.0 * (1.0 - dst.b) * (1.0 - src.b)); }
    return blend_result;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 dst = texture(screen_texture, SCREEN_UV);
	vec4 src = texture(TEXTURE,UV);
	if (src.a > 0.0) {
    	COLOR = vec4(src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a) + src.a * dst.a * blend_func(src.rgb / src.a, dst.rgb / dst.a), src.a + dst.a * (1.0 - src.a));
    } else {
        COLOR = dst;
    }
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

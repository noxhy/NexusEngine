shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform mat4 world_matrix;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;
}
vec3 blend_func(vec3 src, vec3 dst) {
    return src * dst;
}
void fragment() {
	// Called for every pixel the material is visible on.
	vec4 dst = texture(screen_texture, SCREEN_UV);
	vec4 src = texture(TEXTURE, UV);
	if (src.a > 0.0) {
		if (dst.a > 0.0) {
           COLOR = vec4(src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a) + src.a * dst.a * blend_func(src.rgb / src.a, dst.rgb / dst.a), src.a + dst.a * (1.0 - src.a));
        } else {
            COLOR = src;
        }
    } else {
        COLOR = dst;
    }
}

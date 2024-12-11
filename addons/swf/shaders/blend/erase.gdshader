shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform mat4 world_matrix;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 dst = texture(screen_texture, SCREEN_UV);
	vec4 src = texture(TEXTURE, UV);
	if (src.a > 0.0) {
		COLOR = vec4(dst.rgb * (1.0 - src.a), (1.0 - src.a) * dst.a);
    } else {
        COLOR = dst;
    }
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

shader_type canvas_item;
#include "res://assets/shaders/color_transform.gdshaderinc"

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
		//vec4 res = vec4(src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a) + src.a * dst.a * blend_func(src.rgb / src.a, dst.rgb / dst.a), src.a + dst.a * (1.0 - src.a));
		vec4 res = max(dst,src);
		if (res.a >  0.0){
			//res = vec4(res.rgb / res.a, res.a);
			res = res * mult_color + add_color;
			COLOR.a = COLOR.a * mult_color.a + add_color.a;
		}
		COLOR.rgb = res.rgb;
    } else {
        COLOR = dst;
    }
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

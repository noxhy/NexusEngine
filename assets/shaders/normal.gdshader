shader_type canvas_item;

#include "res://assets/shaders/color_matrix.gdshaderinc"
#include "res://assets/shaders/glow.gdshaderinc"
#include "res://assets/shaders/color_transform.gdshaderinc"

uniform int filter_mode = 1;
uniform mat4 world_matrix;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;
}

void fragment() {
	if ((filter_mode & 2) != 0) {
		bool inner = glow_inner > 0;
		bool knockout = glow_knockout > 0;
		bool composite_source = glow_composite_source > 0;
		float blur = texture(blurred, UV).a;
		vec4 dest = texture(TEXTURE, UV);

		vec4 result = vec4(glow_color.r, glow_color.g, glow_color.b, 1.0);
		if (inner) {
			float alpha = glow_color.a * clamp((1.0 - blur) * glow_strength, 0.0, 1.0);
			if (knockout) {
				result = result * alpha * dest.a;
			}else if (composite_source) {
				result = result * alpha * dest.a + dest * (1.0 - alpha);
			} else {
				result = result * alpha * dest.a;
			}
		} else {
			float alpha = glow_color.a * clamp(blur * glow_strength, 0.0, 1.0);
			if (knockout) {
				result = result * alpha * (1.0 - dest.a);
			}else if (composite_source) {
				result = result * alpha * (1.0 - dest.a) + dest;
			}else {
				result = result * alpha;
			}
		}
		//COLOR = result;
	}
	if ((filter_mode & 8) !=0 ) {
		vec4 src = texture(TEXTURE, UV);
		COLOR = color_filter(src);
	}
}

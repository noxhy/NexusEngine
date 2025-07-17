group_uniforms ColorMatrix;
uniform float r_to_r;
uniform float g_to_r;
uniform float b_to_r;
uniform float a_to_r;
uniform float r_extra;

uniform float r_to_g;
uniform float g_to_g;
uniform float b_to_g;
uniform float a_to_g;
uniform float g_extra;

uniform float r_to_b;
uniform float g_to_b;
uniform float b_to_b;
uniform float a_to_b;
uniform float b_extra;

uniform float r_to_a;
uniform float g_to_a;
uniform float b_to_a;
uniform float a_to_a;
uniform float a_extra;

vec4 color_filter(vec4 src){
	return vec4(
        clamp((r_to_r * src.r / src.a) + (g_to_r * src.g / src.a) + (b_to_r * src.b / src.a) + (a_to_r * src.a) + (r_extra / 255.0), 0.0, 1.0),
        clamp((r_to_g * src.r / src.a) + (g_to_g * src.g / src.a) + (b_to_g * src.b / src.a) + (a_to_g * src.a) + (g_extra / 255.0), 0.0, 1.0),
        clamp((r_to_b * src.r / src.a) + (g_to_b * src.g / src.a) + (b_to_b * src.b / src.a) + (a_to_b * src.a) + (b_extra / 255.0), 0.0, 1.0),
        clamp((r_to_a * src.r / src.a) + (g_to_a * src.g / src.a) + (b_to_a * src.b / src.a) + (a_to_a * src.a) + (a_extra / 255.0), 0.0, 1.0)
	);
}
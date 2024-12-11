shader_type canvas_item;
render_mode blend_add;
#include "res://addons/swf/shaders/color_transform.gdshaderinc"

uniform mat4 world_matrix;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = COLOR * mult_color + add_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

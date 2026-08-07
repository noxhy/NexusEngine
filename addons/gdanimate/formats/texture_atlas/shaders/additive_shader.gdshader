shader_type canvas_item;
render_mode blend_add;

#include "color_matrices.gdshaderinc"

void fragment() {
	COLOR = apply_color_matrix(COLOR);
}
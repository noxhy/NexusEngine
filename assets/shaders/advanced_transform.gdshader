shader_type canvas_item;
#include "res://assets/shaders/color_transform.gdshaderinc"

void fragment()
{
	COLOR *= mult_color;
	COLOR += add_color;
}
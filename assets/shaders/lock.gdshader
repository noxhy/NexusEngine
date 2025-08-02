shader_type canvas_item;

uniform vec3 chroma_key: source_color = vec3(1., 1., 1.);
uniform vec3 replace_color: source_color = vec3(1., 1., 1.);

void fragment() {
	
	if (COLOR.rgb == chroma_key)
	{
		COLOR.rgb = replace_color;
	}
}

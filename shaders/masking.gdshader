shader_type canvas_item;

uniform sampler2D mask;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	vec2 muv = UV;
	muv.y = 1.0 - muv.y;
	COLOR.a = texture(mask, muv).r;
}
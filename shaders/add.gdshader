shader_type canvas_item;

uniform float energy : hint_range(0.1, 2.0, 0.01) = 1.;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	
	COLOR = texture( screen_texture, SCREEN_UV ) + ( texture( TEXTURE, UV ) * energy );
	
}
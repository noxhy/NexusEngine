shader_type canvas_item;

uniform vec3 tint_color : source_color = vec3(1.0, 0.0, 0.0);
uniform float intensity : hint_range(0, 1) = 1.0;

void fragment(){
    vec4 front = texture(TEXTURE, UV);
    COLOR = mix(front, vec4(tint_color, front.a), intensity);
}
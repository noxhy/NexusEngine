shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 ScaleMult = vec2(1.0);

uniform float AuraProgres :hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float TextureLaodMult :hint_range(0.0, 10.0, 0.01) = 8.0;
uniform float Tilling :hint_range(0.0, 60.0, 0.01) = 26.0;
uniform vec2 MovementDirSpeed = vec2(-0.6, 1.0);
uniform vec2 MovementDirSpeed2 = vec2(0.6, 1.0);
uniform sampler2D color_gradiant :repeat_enable, filter_linear_mipmap;
uniform vec2 Noise_Seed = vec2(1.0);

vec2 random(vec2 uv){
	uv += Noise_Seed;
	uv = vec2( dot(uv, vec2(127.1,311.7) ),
		dot(uv, vec2(269.5,183.3) ) );
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
	}
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    float bottom_left = dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0));
    float bottom_right = dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0));
    float top_left = dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0));
    float top_right = dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0));
    float bottom_mix = mix(bottom_left, bottom_right, blur.x);
    float top_mix = mix(top_left, top_right, blur.x);
    float final_value = mix(bottom_mix, top_mix, blur.y);
    // Ajustamos para que el resultado esté en el rango de 0.0 a 1.0
    return (final_value + 1.0) * 0.5;
}
vec4 AuraEffect(vec2 uv, vec4 CurrentColor, sampler2D OriginTexTure){
	vec2 TimeUV = MovementDirSpeed * TIME;//direction
	vec2 TimeUV2 = MovementDirSpeed2 * TIME;//direction
	vec2 ScaleMultFractment = (1.0 - ScaleMult)/2.0;//Scale the outline
	vec2 compos_uv = uv * ScaleMult + ScaleMultFractment; //Scale the outline
	//I don't know about shaders but I got this, this was the key.----> noise(uv * Tilling + TimeUV) * 8.0
	vec4 alpha = textureLod(OriginTexTure, compos_uv, noise(uv * Tilling + TimeUV) * TextureLaodMult);
	vec4 GradientColors = texture(color_gradiant, fract( vec2(-uv.y, uv.x) + (TimeUV * 0.4)) ) * 3.0;
	vec4 sil = GradientColors * noise(uv * Tilling - TimeUV);
	sil.a = alpha.a * noise(uv * Tilling + TimeUV) * noise(uv * Tilling + TimeUV2) * 5.0;
	//return sil;
	return mix(CurrentColor, sil * AuraProgres,  (1.0 - CurrentColor.a));
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = AuraEffect(UV, COLOR, TEXTURE);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

shader_type canvas_item;

uniform float amount = 0.0;

void fragment() {
	if (amount != 0.0) {
		float newAmount = amount/3.338;
		vec2 pixelSize = vec2(newAmount);
		
		vec2 correction = TEXTURE_PIXEL_SIZE * vec2(float(pixelSize.x), float(pixelSize.y)) / vec2(2.0);
		vec2 texture_uv = floor(UV / TEXTURE_PIXEL_SIZE);
		vec2 offset = vec2(mod(texture_uv.x, pixelSize.x), mod(texture_uv.y, pixelSize.y));
		vec2 target = (texture_uv - offset) * TEXTURE_PIXEL_SIZE;
		COLOR = textureLod(TEXTURE, target + correction, 0.0);
	}
}
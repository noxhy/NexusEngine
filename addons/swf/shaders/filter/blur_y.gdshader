shader_type canvas_item;

uniform int num_pass: hint_range(1, 255) = 2;
uniform float blur_y: hint_range(0.0, 255.0) = 5.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 res = vec4(0.0);
	for (int j = 0; j < num_pass; j++) {
		ivec2 size = textureSize(screen_texture, 0);
		float strength = blur_y;
		float full_size = strength < 255.0 ? strength : 255.0;
		if (full_size < 1.0){
			COLOR = texture(screen_texture, SCREEN_UV);
		}else {
			float radius = (full_size - 1.0) / 2.0;
			float m = ceil(radius) - 1.0;
			float alpha = floor(((radius - m) * 255.0)) / 255.0;
			float last_offset = 1.0 / ((1.0 / alpha) + 1.0);
			float last_weight = alpha + 1.0;

			//vec2 direction = horizontal ? vec2(1.0 / float(size.x), 0.0) : vec2(0.0, 1.0 / float(size.y));
			vec2 direction = vec2(0.0, 1.0 / float(size.y));
			vec2 uv = SCREEN_UV-direction * m;
			 // 先采样第一个像素
	  		vec4 total = texture(screen_texture, uv - direction) * alpha;

			vec4 center = vec4(0.0);
			for (float k = 0.5; k < m * 2.0; k += 2.0) {
				center += texture(screen_texture, uv + direction * k);
			}
			total += center * 2.0;

			// 最后一个像素对的采样，使用偏移
			vec2 last_location = uv + direction * (m * 2.0 + last_offset);
			total += texture(screen_texture, last_location) * last_weight;

			// 归一化模糊结果
			vec4 result = total / full_size;
			// 将结果输出，模拟固定点精度
			COLOR = floor(result * 255.0) / 255.0;
		}
	}
}
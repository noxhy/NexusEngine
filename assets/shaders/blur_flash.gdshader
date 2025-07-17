shader_type canvas_item;

// ---------------------------------------------------------------------------
// 2‑D SEPARABLE BLUR  (Godot 4.x)
//  - Works on the sprite itself (default) or on the full screen.
//  - Uses evenly spaced samples within the radius to avoid the "ghost clones"
//    you were seeing.
//  - Set radius_x or radius_y to 0 to disable that axis.
// ---------------------------------------------------------------------------

uniform bool   use_screen       = false;                // true = blur screen
uniform int    num_pass : hint_range(1, 16) = 8;        // samples on each side
uniform float  radius_x : hint_range(0.0, 128.0) = 8.0; // blur radius in px (X)
uniform float  radius_y : hint_range(0.0, 128.0) = 8.0; // blur radius in px (Y)
uniform bool   do_normalize     = true;                // average by weights?

// Only needed when use_screen = true
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 modulate_color : source_color;

void fragment() {
    // Base UV + per‑pixel size -------------------------------------------
    vec2 base_uv = use_screen ? SCREEN_UV : UV;
    vec2 texel   = use_screen ? 1.0 / vec2(textureSize(screen_texture, 0))
                              : TEXTURE_PIXEL_SIZE;

    vec4  sum        = vec4(0.0);
    float weight_sum = 0.0;

    // Pre‑compute step sizes so the samples are **evenly distributed**
    float step_x = radius_x > 0.0 ? radius_x / float(num_pass) : 0.0;
    float step_y = radius_y > 0.0 ? radius_y / float(num_pass) : 0.0;

    // ---------------- Horizontal ----------------------------------------
    if (radius_x > 0.0) {
        for (int i = -num_pass; i <= num_pass; i++) {
            vec2 offs  = vec2(float(i) * step_x * texel.x, 0.0);
            float w    = 1.0 - abs(float(i)) / float(num_pass + 1); // simple weight
            vec4  samp = use_screen ? texture(screen_texture, base_uv + offs)
                                     : texture(TEXTURE,       base_uv + offs);
            sum        += samp * w;
            weight_sum += w;
        }
    }

    // ---------------- Vertical ------------------------------------------
    if (radius_y > 0.0) {
        for (int j = -num_pass; j <= num_pass; j++) {
            // Skip center once if horizontal already did it
            if (radius_x > 0.0 && j == 0) continue;
            vec2 offs  = vec2(0.0, float(j) * step_y * texel.y);
            float w    = 1.0 - abs(float(j)) / float(num_pass + 1);
            vec4  samp = use_screen ? texture(screen_texture, base_uv + offs)
                                     : texture(TEXTURE,       base_uv + offs);
            sum        += samp * w;
            weight_sum += w;
        }
    }

    // ---------------- Output --------------------------------------------
    if (weight_sum == 0.0) {
        COLOR = use_screen ? texture(screen_texture, base_uv)
                           : texture(TEXTURE,       base_uv);
    } else {
        COLOR = do_normalize ? sum / weight_sum : sum;
    }
	
	COLOR.a *= modulate_color.a;
}
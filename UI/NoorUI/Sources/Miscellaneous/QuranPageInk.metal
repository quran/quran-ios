//
//  QuranPageInk.metal
//  QuranEngine
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Neutral pixels this dark or darker count as black ink on light pages.
constant float inkBlackPoint = 0.16;

/// Colors Quran page ink with the theme text color `text` (straight sRGB, alpha ignored).
///
/// - Dark pages (`isDark` is 1) match `colorInvert`, `hueRotation(180°)` and `colorMultiply(text)`:
///   `text · (c + 1 − 2·luma(c))`, so black ink becomes `text` and colors keep their hue.
/// - Light pages level neutral pixels to a black point, then screen them with `text`,
///   `c + text · (1 − c)`, so black and dark gray ink become `text` and white stays white. Both fade
///   out with chroma, which leaves colored art as it is.
[[ stitchable ]] half4 quranPageInk(float2 position, half4 color, float4 text, float isDark) {
    if (color.a <= 0) {
        return color;
    }
    // SwiftUI passes premultiplied colors.
    float3 c = float3(color.rgb) / float(color.a);
    float3 t = text.rgb;
    float3 ink;
    if (isDark > 0.5) {
        // The hue rotation matrix SwiftUI uses, with its Rec. 709 weights. SwiftUI folds the three
        // filters into one matrix, so bright colors exceed 1 before the multiply and clamp after it.
        float luma = dot(c, float3(0.213, 0.715, 0.072));
        ink = t * (c + 1 - 2 * luma);
    } else {
        float chroma = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
        float neutral = 1 - smoothstep(0.02, 0.15, chroma);
        // Some Mushafs print dark gray ink, up to about (28, 33, 39), so treat it as black.
        float3 level = saturate((c - inkBlackPoint) / (1 - inkBlackPoint));
        ink = mix(c, level + t * (1 - level), neutral);
    }
    return half4(half3(saturate(ink)) * color.a, color.a);
}

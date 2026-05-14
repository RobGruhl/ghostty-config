// Subtle "paper & vignette" all-day shader.
//
// What you see:
//   - A very soft radial vignette (~6% darken at the corners).
//   - Barely-perceptible animated film grain (~2% amplitude).
//   - A whisper of warmth in the highlights (~1.5% R-up / B-down).
//
// Effect strength is intentionally below ~10% everywhere so the terminal still
// reads as crisp, untouched text. Designed to be left on permanently without
// fatigue or distraction. Cost is trivial: a couple of dot products and one
// hash per pixel, no loops, no extra texture samples.
//
// Enable in ~/.config/ghostty/config:
//   custom-shader = ~/.config/ghostty/shaders/subtle-paper-vignette.glsl
//   custom-shader-animation = true
//
// custom-shader-animation can be left on (default) — the grain only updates
// while the surface is focused, which is exactly what you want.

// Tweakable knobs — all small by design. Raise cautiously.
const float VIGNETTE_STRENGTH = 0.20; // 0.0 = off, 0.10 = strong
const float VIGNETTE_SOFTNESS = 0.90; // larger = softer falloff
const float GRAIN_AMOUNT      = 0.06;  // peak-to-peak luma jitter
const float WARMTH            = 0.0;   // highlight R/B nudge — 0 on light bg (was 0.05 → orange tint)

// Cheap hash → pseudo-random in [0,1). No texture lookups.
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv  = fragCoord / iResolution.xy;
    vec4 src = texture(iChannel0, uv);
    vec3 col = src.rgb;

    // --- 1. Soft radial vignette -------------------------------------------
    // Distance from center in aspect-corrected UV space (so the vignette is
    // round on widescreen displays instead of egg-shaped).
    vec2 centered = uv - 0.5;
    centered.x *= iResolution.x / iResolution.y;
    float dist = length(centered);
    // smoothstep gives a gentle, photographic falloff.
    float vig = 1.0 - smoothstep(0.35, 0.35 + VIGNETTE_SOFTNESS,
                                 dist + VIGNETTE_SOFTNESS - 0.35);
    // Re-map so center == 1.0 and edges == 1.0 - VIGNETTE_STRENGTH.
    float vigMul = mix(1.0 - VIGNETTE_STRENGTH, 1.0, vig);
    col *= vigMul;

    // --- 2. Whisper of paper warmth in highlights --------------------------
    // Luma weight from Rec. 709. Apply more warmth to brighter pixels so dark
    // background stays neutral and won't pick up a tint.
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    float warmMask = smoothstep(0.35, 0.95, luma);
    col.r += WARMTH * warmMask;
    col.b -= WARMTH * 0.6 * warmMask;

    // --- 3. Animated paper texture (two layers + slow breathing) ----------
    //   (a) High-frequency film grain, quantized to 12fps so it reads as
    //       deliberate texture rather than twitchy noise.
    //   (b) Low-frequency smooth noise that drifts slowly across the
    //       surface — paper-fiber unevenness / faint dust.
    //   (c) Intensity gently breathes over ~16s so the texture feels
    //       organic rather than mechanical.
    float tFrame = floor(iTime * 12.0);
    float hi = hash12(fragCoord + tFrame) - 0.5;   // ∈ [-0.5, 0.5]

    // Bilinear-smoothed mid-freq noise with a slow drift. Cells are
    // sub-glyph scale (~14px) so this reads as paper fiber rather than
    // discrete blotches/spots.
    vec2 lowUV = fragCoord * 0.07 + vec2(iTime * 0.12, iTime * 0.07);
    vec2 lf    = floor(lowUV);
    vec2 lff   = fract(lowUV);
    vec2 lfs   = lff * lff * (3.0 - 2.0 * lff);    // smoothstep weights
    float a = hash12(lf);
    float b = hash12(lf + vec2(1.0, 0.0));
    float c = hash12(lf + vec2(0.0, 1.0));
    float d = hash12(lf + vec2(1.0, 1.0));
    float lo = mix(mix(a, b, lfs.x), mix(c, d, lfs.x), lfs.y) - 0.5;

    // Combine: hi-freq dominant, mid-freq lightly adds organic variation.
    float n = hi * 0.85 + lo * 0.12;
    // Slow breathing — period ~16s, ±15% amplitude.
    float breathe = 1.0 + 0.15 * sin(iTime * 0.4);

    // Suppress grain in true blacks and pure whites where it would alias.
    float grainMask = smoothstep(0.02, 0.08, luma) *
                      (1.0 - smoothstep(0.92, 0.98, luma));
    col += n * GRAIN_AMOUNT * grainMask * breathe;

    fragColor = vec4(col, src.a);
}

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

    // --- 3. Very faint animated film grain ---------------------------------
    // Time-quantized so the grain doesn't shimmer too fast to read against.
    float tFrame = floor(iTime * 24.0);
    float n = hash12(fragCoord + tFrame) - 0.5; // ∈ [-0.5, 0.5]
    // Suppress grain in true blacks and pure whites where it would alias.
    float grainMask = smoothstep(0.02, 0.08, luma) *
                      (1.0 - smoothstep(0.92, 0.98, luma));
    col += n * GRAIN_AMOUNT * grainMask;

    fragColor = vec4(col, src.a);
}

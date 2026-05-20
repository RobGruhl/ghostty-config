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
const float VIGNETTE_STRENGTH = 0.06; // 0.0 = off, 0.10 = strong
const float VIGNETTE_SOFTNESS = 1.20; // larger = softer falloff
const float GRAIN_AMOUNT      = 0.018; // peak-to-peak luma jitter
const float WARMTH            = 0.0;   // highlight R/B nudge — 0 on light bg (was 0.05 → orange tint)
const float EMBOSS_AMOUNT     = 0.014; // fake directional light on fiber noise
const float INNER_SHADOW      = 0.02;  // recessed-paper shadow band near edges
const float CURL_AMOUNT       = 0.004; // diagonal sweep — "light catching a page warp"
const float DROP_SHADOW       = 0.09;  // text-drop-shadow strength (0 = off)
const vec2  SHADOW_OFFSET_PX  = vec2(1.0, -1.0); // down-right in screen (y-down)

// Focus-aware framing — preserves text legibility on unfocused surfaces
// (no brightness dim). Three cues stack:
//   COOL_TINT_AMOUNT       — unfocused: slight cool/blue shift, chromatic only
//   UNFOCUS_VIGNETTE_BOOST — unfocused: corners darken further
//   FOCUS_GLOW_AMOUNT      — focused:   soft additive ring just inside the frame
//   FOCUS_FADE_SEC         — crossfade duration when focus flips
const float COOL_TINT_AMOUNT       = 0.18;
const float UNFOCUS_VIGNETTE_BOOST = 0.10;
const float FOCUS_GLOW_AMOUNT      = 0.04;
const float FOCUS_FADE_SEC         = 0.35;

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

    // --- 0. Faux drop-shadow on glyphs (2-tap blurred) ---------------------
    // Sample the framebuffer *behind* this pixel (opposite of the shadow
    // direction) at two distances — one full offset and one half-offset —
    // and average. This produces a sub-pixel-blurred shadow that stays
    // soft on low-DPI monitors where a 1px single-tap would read as a
    // hard stamp, while still being crisp on Retina. Only applied where
    // this pixel is brighter than the neighbor, so text itself isn't
    // double-darkened.
    vec2  shOffFull = SHADOW_OFFSET_PX         / iResolution.xy;
    vec2  shOffHalf = SHADOW_OFFSET_PX * 0.5   / iResolution.xy;
    vec3  nFull   = texture(iChannel0, uv - shOffFull).rgb;
    vec3  nHalf   = texture(iChannel0, uv - shOffHalf).rgb;
    vec3  neighbor = (nFull + nHalf) * 0.5;
    float hereL  = dot(col,      vec3(0.2126, 0.7152, 0.0722));
    float nbrL   = dot(neighbor, vec3(0.2126, 0.7152, 0.0722));
    // Positive only when neighbor is darker (a glyph edge behind us).
    float shadow = max(hereL - nbrL, 0.0);
    col *= 1.0 - DROP_SHADOW * shadow;

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

    // --- 1b. Inner shadow (recessed-paper band) ----------------------------
    // A tight darkening just inside the frame — sells the idea that the
    // paper is set into a tray rather than floating flush. Band peaks near
    // the very edge and fades quickly inward, so it doesn't double up with
    // the main vignette in the middle of the screen.
    float edgeT = smoothstep(0.45, 0.62, dist); // 0 inside, 1 at corners
    // Hump shape: rises then falls so the darkest line is near the edge.
    float band = edgeT * (1.0 - smoothstep(0.62, 0.78, dist));
    col *= 1.0 - INNER_SHADOW * band;

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

    // --- 4. Faux emboss on paper fibers ------------------------------------
    // Estimate the noise-field gradient from the four corner hashes we
    // already have (a,b,c,d), then dot it with a fixed light direction.
    // The result reads as directional relief on the fibers — the grain
    // gains real "tooth" instead of sitting flat on the glass. Zero extra
    // hashes; just a few mixes and one dot.
    float gx = mix(b - a, d - c, lfs.y);   // ∂noise/∂x
    float gy = mix(c - a, d - b, lfs.x);   // ∂noise/∂y
    // Light from upper-left (screen-space y points down, hence negative gy).
    float emboss = gx * -0.707 + gy * -0.707;
    col += emboss * EMBOSS_AMOUNT * grainMask;

    // --- 5. Slow page-curl highlight ---------------------------------------
    // A very low-amplitude diagonal brightness sweep, ~12s period, biased
    // to highlights only so dark background stays put. Reads as light
    // catching a gentle warp in the page.
    float curlPhase = (uv.x + uv.y) * 1.4 - iTime * 0.25;
    float curl = sin(curlPhase) * 0.5 + 0.5;         // [0,1]
    // Narrow band: only the crest contributes, not the whole sweep.
    curl = smoothstep(0.75, 1.0, curl);
    float curlMask = smoothstep(0.30, 0.85, luma);   // highlights only
    col += CURL_AMOUNT * curl * curlMask;

    // --- 6. Focus framing (no brightness dim) ------------------------------
    // Three stacked cues: cool tint shift + extra vignette darkening on
    // unfocused windows, plus an inner edge glow on the focused one.
    // Brightness/contrast on text is left untouched so unfocused panes
    // remain fully readable.
    float sinceFlip = iTime - iTimeFocus;
    float fade      = clamp(sinceFlip / FOCUS_FADE_SEC, 0.0, 1.0);
    float target    = (iFocus > 0) ? 0.0 : 1.0;       // 1 = unfocused
    float unfocusT  = mix(1.0 - target, target, fade); // 0 focused, 1 unfocused

    // (a) Cool/blue tint — shift hue toward blue, scaled by luma so dark
    //     text doesn't pick up a halo but bright cream backgrounds do.
    //     Previously gated on chromatic content, but cream has very low
    //     chroma so the shift was invisible exactly where it was needed.
    float coolK  = COOL_TINT_AMOUNT * unfocusT * luma;
    col.r -= coolK * 0.7;
    col.g -= coolK * 0.25;
    col.b += coolK * 0.5;

    // (b) Unfocus vignette boost — corners darken further; center barely
    //     touched so on-screen text near the middle stays the same.
    float unfocusVig = smoothstep(0.30, 0.70, dist);  // 0 center → 1 corners
    col *= 1.0 - UNFOCUS_VIGNETTE_BOOST * unfocusT * unfocusVig;

    // (c) Focus glow — soft additive ring just inside the frame, only on
    //     the focused window. Peaks ~0.55 from center, fades inward and
    //     outward, so the frame "lifts" without affecting the text region.
    float ringT = (1.0 - unfocusT);
    float ring  = smoothstep(0.40, 0.55, dist) *
                  (1.0 - smoothstep(0.55, 0.72, dist));
    col += FOCUS_GLOW_AMOUNT * ringT * ring;

    fragColor = vec4(col, src.a);
}

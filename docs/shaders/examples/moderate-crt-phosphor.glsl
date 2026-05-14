// Moderate CRT phosphor effect: gentle screen curvature, soft scanlines,
// a touch of RGB chromatic aberration toward the edges, a warm phosphor
// glow biased by bright pixels, and a subtle vignette. Tuned so terminal
// text stays crisp and readable — the vibe is "old workstation monitor"
// not "blown-out arcade".
//
// Enable by saving this file (e.g. to ~/.config/ghostty/shaders/) and
// adding to ~/.config/ghostty/config:
//
//   custom-shader = ~/.config/ghostty/shaders/moderate-crt-phosphor.glsl
//   custom-shader-animation = true
//
// Reload Ghostty config with Cmd+Shift+, on macOS. If the screen goes
// black, remove the line and check Ghostty's log for a shader compile
// error.
//
// Pipeline notes:
//   - Pure GLSL ES 3.00 / Shadertoy dialect. Transpiles cleanly to MSL
//     via glslang -> SPIRV-Cross on macOS (no integer-bitcast tricks,
//     no derivatives, no non-constant array indexing).
//   - Single shader pass; combine with other custom-shader entries by
//     stacking them in declaration order if desired.

// --- tunables -------------------------------------------------------------
const float CURVATURE      = 0.06;  // 0.0 = flat, ~0.15 = strong bulge
const float SCANLINE_AMT   = 0.10;  // 0.0 = off, ~0.25 = heavy
const float SCANLINE_FREQ  = 1.6;   // multiplier on screen height
const float ABERRATION     = 1.2;   // pixels of R/B split at the edges
const float VIGNETTE_AMT   = 0.28;  // 0.0 = off, ~0.5 = dark corners
const float GLOW_AMT       = 0.18;  // additive bloom strength
const float GLOW_RADIUS    = 2.2;   // pixels for the cheap blur taps
const float FLICKER_AMT    = 0.012; // subtle 60Hz-ish brightness wobble
// --------------------------------------------------------------------------

// Barrel-distort UVs around the screen center to simulate CRT curvature.
// Returns UVs in [0,1] (may go slightly outside, which we mask later).
vec2 curve(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(6.0 / CURVATURE);
    uv = uv + uv * offset * offset;
    return uv * 0.5 + 0.5;
}

// Cheap 5-tap separable-ish blur, used only to compute a bloom mask from
// bright pixels. Not applied to the sharp text itself.
vec3 sampleGlow(vec2 uv, vec2 px) {
    vec3 sum = vec3(0.0);
    sum += texture(iChannel0, uv + vec2( GLOW_RADIUS, 0.0) * px).rgb;
    sum += texture(iChannel0, uv + vec2(-GLOW_RADIUS, 0.0) * px).rgb;
    sum += texture(iChannel0, uv + vec2(0.0,  GLOW_RADIUS) * px).rgb;
    sum += texture(iChannel0, uv + vec2(0.0, -GLOW_RADIUS) * px).rgb;
    sum += texture(iChannel0, uv).rgb;
    return sum / 5.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 px  = 1.0 / res;
    vec2 uv0 = fragCoord / res;

    // 1. Curvature: warp UVs around the center.
    vec2 uv = curve(uv0);

    // If a curved sample falls outside the panel, fade to background black.
    // This gives the classic rounded-tube border without smearing edge pixels.
    vec2 edge = smoothstep(vec2(0.0), vec2(0.01), uv) *
                (1.0 - smoothstep(vec2(0.99), vec2(1.0), uv));
    float mask = edge.x * edge.y;

    // 2. Chromatic aberration: split R and B horizontally, amount scaled by
    //    distance from screen center so the middle (where you read) stays
    //    sharp. Sub-pixel offset keeps text legible.
    vec2 centered = uv0 * 2.0 - 1.0;
    float radial  = dot(centered, centered);          // 0 center -> ~2 corners
    vec2 ca = vec2(ABERRATION, 0.0) * px * radial;

    float r = texture(iChannel0, uv + ca).r;
    float g = texture(iChannel0, uv     ).g;
    float b = texture(iChannel0, uv - ca).b;
    vec3 col = vec3(r, g, b);

    // 3. Phosphor glow: additive bloom from bright pixels only. Threshold so
    //    background gray isn't amplified — preserves contrast on dark themes.
    vec3 glowSrc = sampleGlow(uv, px);
    vec3 bright  = max(glowSrc - vec3(0.45), vec3(0.0));
    col += bright * GLOW_AMT;

    // 4. Scanlines: horizontal sine over screen Y. Kept gentle (10% by
    //    default) so they read as texture, not as a barrier between you and
    //    your text. Slowly rolling phase adds liveness without distraction.
    float scan = sin((uv.y * res.y) * SCANLINE_FREQ * 3.14159 + iTime * 0.5);
    col *= 1.0 - SCANLINE_AMT * (0.5 + 0.5 * scan);

    // 5. Subtle line-frequency flicker, like an old monitor's PSU hum.
    float flicker = 1.0 + FLICKER_AMT * sin(iTime * 60.0 * 3.14159);
    col *= flicker;

    // 6. Vignette: darken corners. Reuses the radial term from step 2.
    float vignette = 1.0 - VIGNETTE_AMT * radial;
    col *= vignette;

    // 7. Apply edge mask last so the curved panel sits inside a black bezel.
    col *= mask;

    // Preserve alpha from the original (Ghostty's iChannel0 is opaque, but
    // play nice with any downstream stacked shaders).
    float a = texture(iChannel0, uv).a;
    fragColor = vec4(col, a);
}

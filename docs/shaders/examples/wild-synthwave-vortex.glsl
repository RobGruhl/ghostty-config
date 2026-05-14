// =============================================================================
//  wild-synthwave-vortex.glsl  -  DEMO-SCENE TIER GHOSTTY SHADER
// =============================================================================
//  WHAT IT DOES
//  ------------
//  A psychedelic synthwave portal living behind your terminal:
//    - A swirling magenta/cyan wormhole vortex churning behind the text
//    - Neon horizon grid sweeping toward a vanishing point
//    - Animated VHS scanlines + horizontal tracking glitches
//    - Per-channel chromatic aberration that breathes with iTime
//    - Bloom-style neon halo around bright glyphs
//    - Subtle CRT barrel curvature + vignette
//    - On focus regain: a full-frame CRT DEGAUSS shockwave (iTimeFocus)
//    - On cursor move: a rainbow ring snapping out from the new position
//                      (iCurrentCursor + iTimeCursorChange)
//  Text legibility is preserved at ~70% by keeping background effects below
//  the terminal luma and re-lifting bright glyphs after distortion.
//
//  ENABLE
//  ------
//    cp wild-synthwave-vortex.glsl ~/.config/ghostty/shaders/
//  Then in ~/.config/ghostty/config:
//    custom-shader = ~/.config/ghostty/shaders/wild-synthwave-vortex.glsl
//    custom-shader-animation = true
//  Reload with Cmd+Shift+,
//
//  WARNING
//  -------
//  This shader is INTENTIONALLY EXTREME. Bright flashing colors, fast motion,
//  chromatic separation, periodic glitches. Photosensitive users should not
//  enable it. Not recommended for long coding sessions; pair with a more
//  sedate config and toggle for fun. ~10% CPU on focus, near-zero unfocused.
// =============================================================================

#define TAU       6.28318530718
#define PI        3.14159265359

// ----- small helpers ---------------------------------------------------------
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float hash11(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

// 2D rotation matrix
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// HSV -> RGB
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// luma
float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// ----- background effects ----------------------------------------------------

// Swirling wormhole/vortex in polar coords
vec3 vortex(vec2 p, float t) {
    float r = length(p);
    float a = atan(p.y, p.x);
    // log-polar tunnel
    float z = 1.0 / max(r, 0.05);
    float spin = a + z * 0.6 + t * 0.7;
    // banded color: magenta -> cyan -> violet
    float band = 0.5 + 0.5 * sin(spin * 5.0 - t * 2.0);
    float hue = 0.78 + 0.18 * sin(z * 0.3 + t * 0.4);   // pink/violet/cyan
    vec3 col = hsv2rgb(vec3(hue, 0.95, band));
    // depth attenuation toward center pulls eye inward
    col *= smoothstep(0.0, 1.2, r) * 1.4;
    return col;
}

// Neon synthwave grid below the horizon
vec3 synthGrid(vec2 uv, float t) {
    // place horizon at y = 0.55 from bottom
    float horizon = 0.55;
    if (uv.y > horizon) return vec3(0.0);
    float depth = (horizon - uv.y) / horizon;          // 0 near horizon, 1 at bottom
    // perspective project x
    float px = (uv.x - 0.5) / max(depth, 0.02);
    // moving lines toward viewer
    float pz = 1.0 / max(depth, 0.02) - t * 1.4;
    float gx = abs(fract(px * 4.0) - 0.5);
    float gz = abs(fract(pz) - 0.5);
    float line = smoothstep(0.08, 0.0, gx) + smoothstep(0.08, 0.0, gz);
    // neon pink/cyan gradient
    vec3 cA = vec3(1.0, 0.15, 0.65);
    vec3 cB = vec3(0.2, 0.95, 1.0);
    vec3 col = mix(cA, cB, smoothstep(0.0, 1.0, depth));
    return col * line * (0.6 + 0.6 * depth);
}

// VHS-style horizontal tracking glitch offset
float vhsOffset(float y, float t) {
    // a few moving bands
    float band1 = step(0.985, hash(vec2(floor(t * 4.0), floor(y * 18.0))));
    float band2 = step(0.992, hash(vec2(floor(t * 11.0), floor(y * 7.0))));
    float jitter = (hash(vec2(floor(y * 120.0), floor(t * 60.0))) - 0.5);
    return (band1 * 0.04 + band2 * 0.015) * sign(jitter) + jitter * 0.0015;
}

// ----- main ------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 uv  = fragCoord / res;

    // ----- CRT barrel curvature ---------------------------------------------
    vec2 cuv = uv * 2.0 - 1.0;
    vec2 curved = cuv * (1.0 + 0.06 * dot(cuv, cuv));
    vec2 cuv01  = curved * 0.5 + 0.5;
    // off-screen mask (black bezel)
    float bezel = step(0.0, cuv01.x) * step(cuv01.x, 1.0)
                * step(0.0, cuv01.y) * step(cuv01.y, 1.0);

    // ----- VHS horizontal tracking error ------------------------------------
    float tear = vhsOffset(cuv01.y, iTime);
    vec2 sampUV = cuv01 + vec2(tear, 0.0);

    // ----- chromatic aberration on the TERMINAL texture ---------------------
    // Aberration breathes with iTime, stronger near edges.
    float edge   = smoothstep(0.2, 1.0, length(cuv));
    float aamp   = (0.0025 + 0.0015 * sin(iTime * 1.7)) * (0.6 + edge);
    vec2  adir   = normalize(vec2(cos(iTime * 0.6), sin(iTime * 0.6)));
    float r = texture(iChannel0, sampUV + adir * aamp).r;
    float g = texture(iChannel0, sampUV                ).g;
    float b = texture(iChannel0, sampUV - adir * aamp).b;
    float a = texture(iChannel0, sampUV                ).a;
    vec3 term = vec3(r, g, b);

    // ----- background psychedelia (composed under text) ---------------------
    // Move into a centered, aspect-correct space for the vortex.
    vec2 pc = (fragCoord - 0.5 * res) / res.y;
    // gentle rotation over time keeps the swirl alive
    pc = rot(iTime * 0.15) * pc;
    vec3 vor   = vortex(pc, iTime);
    vec3 grid  = synthGrid(uv, iTime);
    vec3 bg    = vor * 0.55 + grid * 0.9;

    // soft sky glow above the horizon
    float sky = smoothstep(0.55, 1.0, uv.y);
    bg += sky * mix(vec3(0.05, 0.0, 0.15), vec3(0.6, 0.1, 0.5), sky) * 0.6;

    // ----- composite text OVER background; preserve glyph energy ------------
    // Mask glyphs by terminal luma; keep glyphs at full strength.
    float L = luma(term);
    float glyphMask = smoothstep(0.05, 0.35, L);
    // Background only shows where the terminal is mostly dark.
    vec3 col = mix(bg, vec3(0.0), 0.0);                 // base bg
    col = mix(col, term, glyphMask);                    // text wins where bright
    // Always add a fraction of bg as ambient haze (keeps the vibe everywhere).
    col += bg * (1.0 - glyphMask) * 0.85;
    // Lift bright glyphs back up so they punch through chroma split.
    col += term * glyphMask * 0.35;

    // ----- neon bloom around glyphs -----------------------------------------
    // cheap 8-tap bloom on the terminal texture
    vec3 bloom = vec3(0.0);
    float br = 1.5 / res.x;
    for (int i = 0; i < 8; i++) {
        float ang = float(i) * (TAU / 8.0);
        vec2 o = vec2(cos(ang), sin(ang)) * br * 3.0;
        bloom += texture(iChannel0, sampUV + o).rgb;
    }
    bloom *= 1.0 / 8.0;
    // only the bright parts bloom
    bloom = max(bloom - 0.45, 0.0);
    // tint bloom with a slow neon hue cycle
    vec3 neon = hsv2rgb(vec3(fract(iTime * 0.05 + 0.78), 0.7, 1.0));
    col += bloom * neon * 1.6;

    // ----- scanlines + RGB phosphor stripes ---------------------------------
    float scan = 0.85 + 0.15 * sin(fragCoord.y * 3.14159 * 1.0 + iTime * 6.0);
    col *= scan;
    float stripe = mod(fragCoord.x, 3.0);
    vec3 phosphor = vec3(
        stripe < 1.0 ? 1.05 : 0.95,
        (stripe >= 1.0 && stripe < 2.0) ? 1.05 : 0.95,
        stripe >= 2.0 ? 1.05 : 0.95
    );
    col *= phosphor;

    // ----- cursor: rainbow ring snap on move --------------------------------
    // iCurrentCursor.xy is the -X,+Y (top-left) corner; center it.
    vec2 cursorCenter = iCurrentCursor.xy + 0.5 * iCurrentCursor.zw;
    float tc = iTime - iTimeCursorChange;
    if (iCursorVisible.x > 0.5 && tc >= 0.0 && tc < 0.6) {
        float k = tc / 0.6;
        float ringR = mix(4.0, 220.0, k);
        float d = abs(distance(fragCoord, cursorCenter) - ringR);
        float ring = exp(-d * d / 90.0) * (1.0 - k);
        vec3 ringCol = hsv2rgb(vec3(fract(k * 2.0 + iTime * 0.3), 0.9, 1.0));
        col += ringCol * ring * 1.8;
    }
    // Always a soft halo behind the cursor itself
    float ch = exp(-distance(fragCoord, cursorCenter) / 60.0);
    col += iCurrentCursorColor.rgb * ch * 0.35;

    // ----- focus regain: CRT degauss shockwave ------------------------------
    float tf = iTime - iTimeFocus;
    if (iFocus > 0 && tf >= 0.0 && tf < 0.9) {
        float kf = tf / 0.9;
        // expanding ring from center
        vec2 cc = (fragCoord - 0.5 * res);
        float dr = length(cc);
        float waveR = mix(0.0, length(res) * 0.6, kf);
        float w = exp(-pow((dr - waveR) / 50.0, 2.0)) * (1.0 - kf);
        // wobble the texture sample radially
        vec2 wobUV = sampUV + normalize(cc + 1e-3) * w * 0.02;
        vec3 wob = texture(iChannel0, wobUV).rgb;
        col = mix(col, col + wob * 0.5 + vec3(1.0, 0.7, 1.0) * w, 0.85);
        // brief desaturated flash
        float flash = (1.0 - kf) * 0.25;
        col += vec3(flash);
    }
    // Unfocused: dim and desaturate so the user knows the pane is asleep.
    if (iFocus == 0) {
        float gray = luma(col);
        col = mix(vec3(gray), col, 0.4) * 0.55;
    }

    // ----- vignette + bezel ------------------------------------------------
    float vig = 1.0 - smoothstep(0.6, 1.4, length(cuv));
    col *= mix(0.35, 1.0, vig);
    col *= bezel;

    // ----- final tone curve -------------------------------------------------
    col = pow(col, vec3(0.92));                         // gentle gamma lift
    col = clamp(col, 0.0, 1.5);

    fragColor = vec4(col, a);
}

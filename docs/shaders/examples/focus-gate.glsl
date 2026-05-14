// Minimal focus-aware skeleton. When the surface is unfocused, pass the
// terminal through unchanged. Use this as the starting point for any
// focus-aware effect.
//
// Pattern source: Martin Emde —
//   https://martinemde.com/blog/ghostty-focus-shaders
//
// Why early-return: unfocused surfaces still receive occasional "deceptive
// frames" from modifier keys / hover events, which cause large iTimeDelta
// spikes that visually stutter time-based animation.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    if (iFocus == 0) {
        fragColor = c;
        return;
    }

    // === your focused-only effect here ===
    // Example placeholder: subtle warm tint when focused.
    fragColor = vec4(c.rgb * vec3(1.02, 1.00, 0.96), c.a);
}

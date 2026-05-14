// Brief brightness pulse whenever the surface regains focus. Uses iTimeFocus
// to clock the animation from focus-event time, so the pulse plays the same
// way every time you click into the pane.
//
// Pattern source: Martin Emde —
//   https://martinemde.com/blog/ghostty-focus-shaders

const float PULSE_DURATION = 0.15;  // seconds

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    float t = iTime - iTimeFocus;
    if (iFocus == 0 || t < 0.0 || t > PULSE_DURATION) {
        fragColor = c;
        return;
    }

    // 1.0 at t=0, fading to 0.0 at t=PULSE_DURATION
    float k = 1.0 - smoothstep(0.0, PULSE_DURATION, t);
    fragColor = vec4(c.rgb + k * 0.25, c.a);
}

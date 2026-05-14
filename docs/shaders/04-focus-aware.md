---
title: Focus-Aware Shaders
chapter: 4
---

# Focus-Aware Shaders

The `iFocus` / `iTimeFocus` uniforms are a Ghostty extension that let one
shader behave differently per pane — fade unfocused panes, pulse on focus
regain, gate animation, etc. Especially useful in tmux/zellij/native-split
workflows where 4+ terminals share the screen.

## The two uniforms

```glsl
int   iFocus;       // 1 when this surface is focused, 0 otherwise
float iTimeFocus;   // iTime at the moment focus was last gained
```

Both are documented in [chapter 3](03-uniforms-reference.md) and quoted from
the Ghostty source.

## Pattern 1 — focus gate (passthrough when unfocused)

Skip your effect entirely on unfocused surfaces. This is the cheapest possible
focus-aware shader and the recommended early-out per Martin Emde:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    if (iFocus == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // ... your real effect here ...
}
```

This also dodges a real-world artifact: unfocused surfaces still receive
occasional "deceptive frames" from modifier-key presses and hover events, which
produce large `iTimeDelta` spikes that visually stutter time-based animation.

See [`examples/focus-gate.glsl`](examples/focus-gate.glsl).

## Pattern 2 — dim the unfocused

The opposite — leave the focused pane alone, only modify unfocused ones:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    if (iFocus > 0) {
        fragColor = c;
        return;
    }

    // Desaturate + dim unfocused panes
    float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    fragColor = vec4(mix(c.rgb, vec3(gray), 0.6) * 0.55, c.a);
}
```

Combine with `custom-shader-animation = always` (see
[chapter 6](06-stacking-and-perf.md)) if you want unfocused panes to *animate*
their effect (e.g. a slow CRT scanline drift). Otherwise the dim is static,
which is fine.

## Pattern 3 — focus-restart pulse

A short animation that plays whenever the surface regains focus, using
`iTimeFocus` as the start time:

```glsl
const float PULSE_DURATION = 0.15;  // seconds

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    float t = iTime - iTimeFocus;
    if (iFocus == 0 || t < 0.0 || t > PULSE_DURATION) {
        fragColor = c;
        return;
    }

    // Bright flash that fades out over PULSE_DURATION
    float k = 1.0 - smoothstep(0.0, PULSE_DURATION, t);
    fragColor = vec4(c.rgb + k * 0.25, c.a);
}
```

See [`examples/focus-pulse.glsl`](examples/focus-pulse.glsl).

## Pattern 4 — heavy effect only on unfocused panes

Per Martin Emde, a great use of focus state is **CRT scanlines / vignette /
blur on *unfocused* panes only** so your active terminal stays clean and
readable, while the inactive ones look like dead monitors. The structure:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    if (iFocus > 0) {
        fragColor = c;
        return;
    }

    // scanlines
    float scan = 0.85 + 0.15 * sin(uv.y * iResolution.y * 3.14159);
    // vignette
    vec2 v = uv - 0.5;
    float vig = 1.0 - dot(v, v) * 1.2;
    fragColor = vec4(c.rgb * scan * vig, c.a);
}
```

## Stacking focus-aware shaders

If you have multiple shaders and want consistent behavior, gate each one with
the same `iFocus` early-return. Or — cleaner — keep your bling shaders
focus-naïve and add one final `focus-gate.glsl` pass on top that:

- if focused: returns `iChannel0` unchanged (the result of the bling stack);
- if unfocused: samples a *desaturated/dimmed* version.

Order in your config:

```conf
custom-shader = ~/.config/ghostty/shaders/retro-terminal.glsl
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
custom-shader = ~/.config/ghostty/shaders/focus-dim.glsl   # last
```

## Caveat: version

The `iFocus` / `iTimeFocus` uniforms landed in a Ghostty 1.x development build
(prerelease as of Martin Emde's writeup). If your shader compiles but the
uniforms are always 0, you're likely on an older build — check `ghostty
--version` and update.

Live demo + writeup: <https://martinemde.com/blog/ghostty-focus-shaders>.

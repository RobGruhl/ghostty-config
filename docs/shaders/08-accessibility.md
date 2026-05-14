---
title: Accessibility Uses
chapter: 8
---

# Accessibility Uses

Per Mitchell Hashimoto in Devlog 005, accessibility is the **primary serious
motivation** for Ghostty's shader system — first-class a11y features are
still under development, and shaders are the bridge.

This chapter sketches starter implementations; ship one and tune the
parameters to your eyes.

## Colorblind correction

Most "colorblind filters" use a Brettel-Viénot-Mollon (BVM) or LMS-based
daltonization transform. A simplified, fast version:

```glsl
// Deuteranopia (red-green confusion) simulation — useful as a starter to
// pre-distort the *terminal output* so red and green become distinguishable.

const mat3 RGB_TO_LMS = mat3(
    17.8824,  43.5161,  4.11935,
    3.45565, 27.1554,   3.86714,
    0.0299566, 0.184309, 1.46709
);
const mat3 LMS_TO_RGB = mat3(
    0.0809444479, -0.130504409,  0.116721066,
   -0.0102485335,  0.0540193266,-0.113614708,
   -0.000365296938,-0.00412161469,0.693511405
);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 c = texture(iChannel0, uv).rgb;

    vec3 lms = RGB_TO_LMS * c;
    // shift the green-deficient cone — daltonization
    lms.y = mix(lms.y, lms.x * 0.494207 + lms.z * 1.24827, 1.0);
    vec3 corrected = LMS_TO_RGB * lms;

    fragColor = vec4(clamp(corrected, 0.0, 1.0), 1.0);
}
```

This is a rough sketch — for production a11y, prefer
[Daltonize](https://en.wikipedia.org/wiki/Color_blindness#Computer_assistance)
or a research-grade BVM implementation. Two variants you'll want to swap in
are protanopia (red-deficient) and tritanopia (blue-deficient).

A complementary approach: don't daltonize the texture — instead build a
theme-aware tint by sampling `iPalette[1]` (ANSI red) and `iPalette[2]` (ANSI
green) and substituting them at the palette layer. Requires more shader logic
but produces sharper text.

## Contrast / brightness boost

For low-vision users — non-destructive contrast lift:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 c = texture(iChannel0, uv).rgb;

    const float CONTRAST = 1.35;
    const float BRIGHTNESS = 0.05;
    vec3 out_c = (c - 0.5) * CONTRAST + 0.5 + BRIGHTNESS;
    fragColor = vec4(clamp(out_c, 0.0, 1.0), 1.0);
}
```

`alpha-blending = linear-corrected` is recommended here so the lift is
gamma-correct (see [chapter 2](02-pipeline.md)).

## Magnifier (cursor-tracked)

A "magnifying glass" effect that follows the cursor, useful for reading dense
output. Uses `iCurrentCursor` from [chapter 5](05-cursor-effects.md):

```glsl
const float RADIUS = 120.0;     // pixels
const float ZOOM = 1.6;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 cur = iCurrentCursor.xy + 0.5 * iCurrentCursor.zw;
    float d = distance(fragCoord, cur);

    if (d > RADIUS) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // sample a zoomed-in region around the cursor
    vec2 offset = (fragCoord - cur) / ZOOM;
    vec2 sample_uv = (cur + offset) / iResolution.xy;
    vec3 zoomed = texture(iChannel0, sample_uv).rgb;

    // soft edge ring
    float k = smoothstep(RADIUS, RADIUS - 4.0, d);
    vec3 base = texture(iChannel0, uv).rgb;
    fragColor = vec4(mix(base, zoomed, k), 1.0);
}
```

You can wire it to `iFocus` so it only shows on the focused pane.

## Focus dimming for multi-pane workflows

Not strictly a11y, but high-value for low-attention environments — see
[chapter 4](04-focus-aware.md) "Pattern 2 — dim the unfocused."

## Caveats

- These are starting points. Real a11y deployments deserve user-tunable
  intensity values — set the constants in your `.glsl` per-user.
- Stack a11y shaders **last** so they apply to the final rendered image.
- Performance is bounded by texture sampling — these run cheap (single
  `texture()` call per pixel).
- Combine with a high-contrast theme (e.g. Ghostty's accessibility-leaning
  built-in themes) for compounding gains.

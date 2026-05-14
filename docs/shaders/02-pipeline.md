---
title: Pipeline & Compatibility
chapter: 2
---

# Pipeline & Compatibility

How Ghostty turns a `.glsl` file on disk into pixels on screen.

## The render pipeline (one frame)

1. Ghostty renders the terminal (text, cursor, background) into a texture
   using its native renderer (Metal on macOS, OpenGL on Linux).
2. That texture is bound as `iChannel0` and the first user shader runs over a
   full-screen quad. Its output is written to a render target.
3. If multiple `custom-shader` entries exist, the previous output becomes the
   next shader's `iChannel0`, and so on. Source: Config.zig — *"the output of
   previous shaders is written to this texture, to allow combining multiple
   effects."*
4. The final output is presented to the window.

Crucially this happens on a **dedicated render thread**. The main / IO threads
aren't blocked by shader work, and shader compilation errors are logged but
don't surface as config errors.

## GLSL → MSL on macOS

Ghostty accepts shaders written in GLSL (Shadertoy dialect, broadly GLSL ES
3.0 / WebGL 2.0 syntax). On macOS the pipeline is:

```
your GLSL  →  glslang  →  SPIR-V  →  SPIRV-Cross  →  MSL  →  Metal
```

Both `glslang` and `SPIRV-Cross` are Khronos open-source tools bound via their
C APIs. The upshot: **you write one shader file that runs on both macOS and
Linux**. (Source: Mitchell Hashimoto, Ghostty Devlog 005.)

On Linux the GLSL is consumed directly by OpenGL with no transpilation step.

## Shadertoy compatibility

Ghostty implements the Shadertoy interface deliberately so that:

- Existing Shadertoy effects drop in unchanged (mostly).
- Shadertoy.com itself becomes the recommended dev environment — live preview,
  error reporting, community library.

Your shader must define:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // ...
}
```

The standard Shadertoy uniforms (`iResolution`, `iTime`, `iTimeDelta`,
`iFrame`, `iChannel0`, `iChannelResolution`) are all supported. A few
Shadertoy uniforms are **declared but not supported** in Ghostty today — see
[chapter 3](03-uniforms-reference.md) for the explicit list (`iMouse`, `iDate`,
`iFrameRate`, `iSampleRate`).

## Color space — `alpha-blending`

The color space your shader receives in `iChannel0` is controlled by the
`alpha-blending` config key. From the official reference:

> What color space to use when performing alpha blending. This affects the
> appearance of text and of any images with transparency. Additionally,
> custom shaders will receive colors in the configured space.

Allowed values:

| Value | Behavior |
|---|---|
| `native` | macOS: Display P3. Linux: sRGB. (macOS default.) |
| `linear` | Alpha blend in linear-light space. |
| `linear-corrected` | Linear, with a text-correction step so output looks ~identical to `native`. (Default on Linux and non-macOS.) |

Available since Ghostty 1.1.0. If your shader does math (lerps, sums, mults)
on the texture, prefer `linear` or `linear-corrected` — gamma-correct blending
avoids the usual "too dark in the middle" artifact. If you're just transforming
colors locally (hue rotate, saturation), `native` is fine.

## Performance

From Mitchell Hashimoto's Devlog 005, measured on his hardware running a CRT
simulation:

> ~1% CPU and ~2% GPU

The reasoning: shader work happens during idle render-thread time. When no
shader is configured, the only cost is a boolean check.

From the Config.zig comment on `custom-shader-animation` (default `true`):

> This uses slightly more CPU (generally less than 10%) but allows the shader
> to animate.

So: **focused, animating** terminal with a non-trivial shader = up to ~10% CPU
per surface; idle / unfocused (with default animation setting) = near zero.
Setting `custom-shader-animation = always` runs the loop on unfocused surfaces
too — *"can become quite expensive depending on the shader and your terminal
usage."*

## Practical implications

- Many shaders open: keep `custom-shader-animation = true` (default), not
  `always`. Unfocused panes will pause.
- Want focus-aware animation that *also* gates inside the shader itself?
  Combine `custom-shader-animation = always` with an `iFocus`-based early
  return — see [chapter 4](04-focus-aware.md).
- Heavy stacks (e.g. 4+ shaders with motion): test on battery before relying
  on them. Stack ordering matters for cost, too: a cheap pass that reduces
  effective resolution early can speed up later passes.

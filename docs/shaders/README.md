---
title: Ghostty Shaders — Curated Knowledge Library
updated: 2026-05-13
---

# Ghostty Shaders

A locally curated library of Ghostty's custom shader system: pipeline, uniform
reference, focus-aware patterns, the community shader catalog, and practical
recipes. Synthesized from primary sources (Ghostty source code, Mitchell
Hashimoto's devlog, Martin Emde, 0xkoji, catskull, and community repos).

Aim: ~80% of what you need to *write and ship* a shader lives in these pages.
The remaining 20% (visual demos, live-coding, deep Shadertoy theory) is linked
out — see [`sources.md`](sources.md).

## What Ghostty shaders are

Ghostty renders the terminal to a texture, then runs zero or more user-supplied
**GLSL fragment shaders** over it before presenting the final frame. Shaders
follow the Shadertoy convention (`mainImage(out vec4 fragColor, in vec2
fragCoord)` with `iChannel0` as the input texture), so most Shadertoy effects
drop in with zero modification. On macOS, GLSL is cross-compiled to Metal
Shading Language on the fly (`glslang` → SPIR-V → `SPIRV-Cross` → MSL); on
Linux, GLSL feeds straight into OpenGL. Source: Ghostty Devlog 005.

## Chapters

1. [Quickstart](01-quickstart.md) — install the community pack, drop a shader
   in, reload.
2. [Pipeline & Compatibility](02-pipeline.md) — GLSL ES 3.0, transpilation,
   color space, performance.
3. [Uniforms Reference](03-uniforms-reference.md) — every uniform Ghostty
   exposes, copied verbatim from the source.
4. [Focus-Aware Shaders](04-focus-aware.md) — `iFocus` / `iTimeFocus` patterns
   for multi-pane workflows.
5. [Cursor Effects](05-cursor-effects.md) — `iCurrentCursor`,
   `iPreviousCursor`, `iTimeCursorChange` (Ghostty-specific extension).
6. [Stacking & Performance](06-stacking-and-perf.md) — `custom-shader-animation`,
   recommended stacks, when not to animate.
7. [Effect Showcase](07-showcase.md) — the community shader catalog at a glance.
8. [Accessibility Uses](08-accessibility.md) — colorblind correction, contrast,
   magnifier, focus dimming.
9. [Experimental](09-experimental.md) — audio-reactive shaders, live-coding,
   prerelease features.

## Examples in this library

- [`examples/perlin-noise-bg.glsl`](examples/perlin-noise-bg.glsl) — animated
  Perlin-noise background blended with the terminal texture (from 0xkoji).
- [`examples/focus-gate.glsl`](examples/focus-gate.glsl) — minimal focus-aware
  passthrough (skeleton from Martin Emde).
- [`examples/focus-pulse.glsl`](examples/focus-pulse.glsl) — pulse animation on
  focus regain using `iTimeFocus`.

## Minimum viable config

```conf
# ~/.config/ghostty/config
custom-shader = ~/.config/ghostty/shaders/retro-terminal.glsl
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
custom-shader-animation = true
```

Multiple `custom-shader` entries stack in declaration order — the output of
each becomes the input (`iChannel0`) of the next. Reload with `Cmd+Shift+,` on
macOS. If the screen goes black, delete the line (see warning in chapter 1).

## Sources & attribution

See [`sources.md`](sources.md) for the full bibliography, including the
Ghostty source files this library quotes from, all community shader repos,
and external blog posts.

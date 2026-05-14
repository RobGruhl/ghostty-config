---
title: Sources & Attribution
---

# Sources & Attribution

Everything in this library was synthesized from these primary sources. Visit
them for screenshots, video demos, comment threads, and the most current API.

## Authoritative: Ghostty itself

- **`ghostty-org/ghostty` — `src/config/Config.zig`**
  <https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig>
  The doc-comments on `custom-shader` and `custom-shader-animation` are the
  ground truth for uniforms and animation behavior. [Chapter 3](03-uniforms-reference.md)
  and [chapter 6](06-stacking-and-perf.md) quote them verbatim.
- **Official config reference**
  <https://ghostty.org/docs/config/reference>
  Quoted prose for `custom-shader`, `alpha-blending` (since 1.1.0).
- **Ghostty docs landing**
  <https://ghostty.org/docs>

## Technical deep-dive (Mitchell Hashimoto)

- **Ghostty Devlog 005 — "Building Ghostty's custom shader system"**
  <https://mitchellh.com/writing/ghostty-devlog-005>
  Source for: GPU pipeline (Metal/OpenGL), GLSL → SPIR-V → MSL transpilation
  via `glslang` + `SPIRV-Cross`, Shadertoy compat philosophy, the *"~1% CPU
  and ~2% GPU"* CRT measurement, the accessibility motivation.

## Focus-aware uniforms (Martin Emde)

- **"Ghostty Focus & Blur Shaders"**
  <https://martinemde.com/blog/ghostty-focus-shaders>
  Source for: `iFocus` / `iTimeFocus` patterns, the focus-gate early-return,
  the focus-pulse animation. Has an interactive live demo on the page —
  recommended visit.

## Background-shader walkthrough (0xkoji)

- **"Ghostty: Use Fragment Shader as Terminal Background" — dev.to**
  <https://dev.to/0xkoji/ghostty-use-fragment-shader-as-terminal-background-11g3>
  Source for: the Perlin-noise background example in
  [`examples/perlin-noise-bg.glsl`](examples/perlin-noise-bg.glsl), the
  config-stacking pattern, troubleshooting.

## Showcase & stack combos

- **catskull — "Fun with Ghostty Shaders"**
  <https://catskull.net/fun-with-ghostty-shaders.html>
  Source for: the full shader catalog in [chapter 7](07-showcase.md), the
  recommended stack combos (`drunkard + retro-terminal + bloom`,
  `tft + bettercrt`, etc.). Video clips for every shader — worth the visit.

## Community shader collections

- **`hackr-sh/ghostty-shaders`** (cited as `0xhckr/ghostty-shaders` in some
  writeups — same org/handle)
  <https://github.com/hackr-sh/ghostty-shaders>
  The canonical 40+ shader collection. Install with:
  `git clone --depth 1 https://github.com/hackr-sh/ghostty-shaders ~/.config/ghostty/shaders`
- **`alex-sherwin/my-ghostty-shaders`**
  <https://github.com/alex-sherwin/my-ghostty-shaders>
- **`fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty`**
  <https://github.com/fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty>
- **`luiscarlospando/crt-shader-...`**
  <https://github.com/luiscarlospando/crt-shader-with-chromatic-aberration-glow-scanlines-dot-matrix>
  Single, very polished CRT shader.
- **`12jihan/ghostty_shaders`**
  <https://github.com/12jihan/ghostty_shaders>
- **`erniee/gshaders`**
  <https://github.com/erniee/gshaders>

## Curated index

- **Awesome-Ghostty**
  <https://github.com/fearlessgeekmedia/Awesome-Ghostty>
  Categories include Shaders, Themes, Tools, Plugins. Source for the shader
  repos listed above.

## Experimental / live-coding

- **r/Ghostty — Live-coding audio-reactive shaders thread**
  <https://www.reddit.com/r/Ghostty/comments/1o28x2j/livecoding_audioreactive_shaders_in_ghostty/>
  Cited in [chapter 9](09-experimental.md). Discussion of binding audio to
  shader uniforms.

## Tooling / dev environment

- **Shadertoy** — Ghostty's officially recommended dev environment.
  <https://shadertoy.com>
  Most Shadertoy effects run in Ghostty unchanged. Note `iMouse`, `iDate`,
  `iFrameRate`, `iSampleRate` are documented as **NOT CURRENTLY SUPPORTED**
  in Ghostty — stub them.

## Glossary cross-reference

| Topic | Primary source for this library |
|---|---|
| Uniforms list | Ghostty Config.zig |
| Pipeline (GLSL→MSL) | Devlog 005 |
| `alpha-blending` | ghostty.org/docs/config/reference |
| `custom-shader-animation` semantics | Config.zig |
| Performance numbers | Devlog 005 + Config.zig |
| `iFocus` / `iTimeFocus` patterns | Martin Emde |
| Background-blend example code | 0xkoji |
| Shader catalog + stacks | catskull |
| Repo list | Awesome-Ghostty |
| Cursor-trail reference impl | `hackr-sh/ghostty-shaders/cursor_blaze.glsl` |

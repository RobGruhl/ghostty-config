---
title: Quickstart
chapter: 1
---

# Quickstart

Goal: get one shader running, then stack a second one. Five minutes.

## 1. Install the community shader pack

The canonical community shader collection is [`hackr-sh/ghostty-shaders`][repo]
(formerly cited as `0xhckr/ghostty-shaders` — same org). 40+ ready-to-use GLSL
files including `retro-terminal`, `bettercrt`, `bloom`, `water`, `glitchy`,
`inside-the-matrix`, `cursor_blaze`, and more (full list in
[chapter 7](07-showcase.md)).

```bash
git clone --depth 1 https://github.com/hackr-sh/ghostty-shaders \
  ~/.config/ghostty/shaders
```

Alternative collections to browse later:

- [`alex-sherwin/my-ghostty-shaders`](https://github.com/alex-sherwin/my-ghostty-shaders)
- [`fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty`](https://github.com/fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty)
- [`luiscarlospando/crt-shader-...`](https://github.com/luiscarlospando/crt-shader-with-chromatic-aberration-glow-scanlines-dot-matrix)
  — single, very polished CRT shader.

## 2. Enable in your Ghostty config

```conf
# ~/.config/ghostty/config
custom-shader = ~/.config/ghostty/shaders/retro-terminal.glsl
custom-shader-animation = true
```

Reload Ghostty with `Cmd+Shift+,` (macOS) — config changes apply at runtime to
all open terminals.

## 3. Stack a second shader

Shaders compose in pipeline order. Each shader's output becomes the next
shader's `iChannel0`:

```conf
custom-shader = ~/.config/ghostty/shaders/retro-terminal.glsl
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
```

The visual rule of thumb: put *grid/structural* effects first (TFT, scanlines,
CRT curve), then *color/glow* effects (bloom, RGB split), then *motion/global*
effects (water, drunkard) last. See [chapter 6](06-stacking-and-perf.md) for
community-tested combinations.

## 4. Verify

If you see the effect — done. If the screen is black, see "Recovery" below.

## ⚠️ Recovery: shader crashed your terminal

From Ghostty's source (Config.zig):

> Warning: Invalid shaders can cause Ghostty to become unusable such as by
> causing the window to be completely black. If this happens, you can unset
> this configuration to disable the shader.

If GUI Ghostty is unusable, edit the config from another terminal (Terminal.app,
SSH session, or a CLI editor) and comment out the `custom-shader` line:

```bash
sed -i.bak 's/^custom-shader/# custom-shader/' ~/.config/ghostty/config
```

Then reopen Ghostty. Shader compilation errors don't show up as config errors —
they appear in the log only. Tail it while developing:

```bash
# macOS — adjust path for your install
tail -f ~/Library/Application\ Support/com.mitchellh.ghostty/logs/*.log
```

## Iterative development

Shadertoy.com is Ghostty's official recommended dev environment. From Config.zig:

> For interactive development, use shadertoy.com.

Write/iterate there with their live-preview, then save the `mainImage` body to
a `.glsl` in `~/.config/ghostty/shaders/` and reload. Almost all Shadertoy
shaders run unmodified — Ghostty implements the Shadertoy uniform interface.

## Next

- Want to understand *why* it works → [chapter 2](02-pipeline.md)
- Want the full uniform list → [chapter 3](03-uniforms-reference.md)
- Want pretty effects → [chapter 7](07-showcase.md)

[repo]: https://github.com/hackr-sh/ghostty-shaders

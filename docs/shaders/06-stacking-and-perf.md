---
title: Stacking & Performance
chapter: 6
---

# Stacking & Performance

How shaders compose, what `custom-shader-animation` actually does, and how to
not melt your laptop.

## Stacking

Each `custom-shader = …` entry in your config adds another fragment pass. The
output of pass *N* is bound as `iChannel0` for pass *N+1*. Order matters.

```conf
custom-shader = ~/.config/ghostty/shaders/tft.glsl       # pass 1
custom-shader = ~/.config/ghostty/shaders/bettercrt.glsl # pass 2
custom-shader = ~/.config/ghostty/shaders/bloom.glsl     # pass 3
```

From Config.zig: *"This can be repeated multiple times to load multiple shaders.
The shaders will be run in the order they are specified."*

### Ordering rule of thumb

1. **Structural / grid effects first** — TFT pixel grid, CRT scanlines,
   dithering. These modulate the texture in a way later passes can pick up.
2. **Geometric distortion middle** — CRT curvature, water ripple, drunkard
   wobble. They warp UVs.
3. **Color / glow effects last** — bloom, RGB split, vignette, color
   correction. They operate on the already-distorted image and produce the
   final look.

This isn't a hard rule — `bloom` after `glitchy` looks great because the
glitch artifacts bloom too. Experiment.

## Community-validated stacks

From catskull.net's "Fun with Ghostty Shaders" gallery:

| Stack | Vibe |
|---|---|
| `drunkard` + `retro-terminal` + `bloom` | wobbly CRT phosphor glow, VHS-nightmare |
| `glitchy` + `bettercrt` + `water` + `bloom` | signal-degraded, rippling chaos |
| `retro-terminal` + `tft` | crisp pixel grid over vintage palette |
| `tft` + `bettercrt` | monitor-within-a-monitor — TFT pixels on a CRT curve |
| `tft` + `retro-terminal` + `bloom` | softer pixel-art aesthetic |

The "TFT-on-CRT" effect is the most-cited gem: stacking a TFT pixel grid
*then* a CRT curve nails the look of a real LCD photographed on a CRT
monitor.

## `custom-shader-animation` — verbatim

From Ghostty's Config.zig:

> If `true` (default), the focused terminal surface will run an animation loop
> when custom shaders are used. This uses slightly more CPU (generally less
> than 10%) but allows the shader to animate. This only runs if there are
> custom shaders and the terminal is focused.
>
> If this is set to `false`, the terminal and custom shader will only render
> when the terminal is updated. This is more efficient but the shader will
> not animate.
>
> This can also be set to `always`, which will always run the animation loop
> regardless of whether the terminal is focused or not. The animation loop
> will still only run when custom shaders are used. Note that this will use
> more CPU per terminal surface and can become quite expensive depending on
> the shader and your terminal usage.

The three values:

| Value | When the shader animates |
|---|---|
| `true` *(default)* | Only while the surface is focused. |
| `false` | Never — re-renders only on terminal updates. |
| `always` | Always — even on unfocused panes. |

### When to use which

- **`true`** — sane default for almost everyone. Idle CPU is zero, focused CPU
  is "<10%" per Ghostty's docs, ~1% CPU / ~2% GPU per Devlog 005 for a CRT.
- **`false`** — picking a static visual style (color correction, posterize,
  retro palette, dithering with no motion). Zero overhead when idle.
- **`always`** — when you've built focus-aware effects that look bad if frozen
  on unfocused panes (e.g. animated dim with a slow drift). Watch power use
  on battery.

## Performance numbers, restated

- Mitchell Hashimoto, Devlog 005, CRT example: *"~1% CPU and ~2% GPU"* on his
  machine.
- Config.zig on default animation: *"generally less than 10%"* CPU when
  focused-and-animating.
- `always` mode: scales linearly with number of surfaces — N panes × per-pane
  cost.

Practical advice for laptops:

1. Profile with one shader before stacking 4.
2. Heavy shaders (Matrix-style, lava, galaxy, multi-octave noise) cost the
   most — keep them to one terminal surface or skip on battery.
3. `bloom` is cheap. `cubes`/`matrix-hallway`/raymarched 3D shaders are not.
4. If a shader looks the same focused vs. unfocused, you can probably switch
   it to `false` and pre-render-on-update with no visual loss.

## Sanity checks if stacking misbehaves

- **Black screen.** Most likely one of the shaders fails to compile. Comment
  them out one at a time. Errors are in the log, not your stderr.
- **Effect "wrong way around."** Reorder. Bloom before geometry distortion
  will glow the un-distorted text; usually you want it last.
- **Performance cliff.** Disable `custom-shader-animation` (set `false`) — if
  framerate recovers, your shader animates expensively. Profile or simplify
  the inner loops.

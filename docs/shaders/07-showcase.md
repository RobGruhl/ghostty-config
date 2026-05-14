---
title: Effect Showcase
chapter: 7
---

# Effect Showcase

Cross-referenced catalog of community shaders. Names below match the
filenames in [`hackr-sh/ghostty-shaders`](https://github.com/hackr-sh/ghostty-shaders),
the canonical community pack. The descriptions are synthesized from catskull's
gallery — visit it for screenshots and short videos:
<https://catskull.net/fun-with-ghostty-shaders.html>.

## CRT & vintage display family

| File | Effect |
|---|---|
| `crt.glsl` | Classic CRT scanlines. |
| `bettercrt.glsl` | Enhanced CRT — curvature, scanlines, fringe. |
| `in-game-crt.glsl` | CRT tuned for readability, lighter scanlines. |
| `retro-terminal.glsl` | Vintage terminal palette + phosphor glow. |
| `tft.glsl` | TFT/LCD pixel-grid look. Pairs beautifully with `bettercrt`. |
| `posters.glsl` | Posterization / color-count reduction. |
| `dither.glsl` | Ordered-dithering pattern. |
| `negative.glsl` | Inverted colors. |

## Glow & color

| File | Effect |
|---|---|
| `bloom.glsl` | Bright-pixel bloom / light diffusion. Cheap, gorgeous. |
| `glow-rgbsplit-twitchy.glsl` | Bloom + RGB channel separation + glitchy jitter. |
| `spotlight.glsl` | Spotlight beam over the terminal. |
| `glitchy.glsl` | Digital signal-corruption artifacts. |

## Motion & distortion

| File | Effect |
|---|---|
| `water.glsl` | Surface-water ripple distortion. |
| `underwater.glsl` | Caustics + slow ripple, "submerged terminal." |
| `drunkard.glsl` | Wobbly, slightly-drunk distortion. |
| `sin-interference.glsl` | Wave-interference pattern. |
| `just-snow.glsl` | Snow particles falling over the screen. |

## Background-only effects (often blended w/ `iChannel0` at low opacity)

| File | Effect |
|---|---|
| `animated-gradient-shader.glsl` | Animated color gradient. |
| `gradient-background.glsl` | Static gradient. |
| `cineShader-Lava.glsl` | Lava-lamp noise field. |
| `starfield.glsl` | Classic parallax stars. |
| `starfield-colors.glsl` | Colored stars. |
| `galaxy.glsl` | Spiral galaxy. |
| `inside-the-matrix.glsl` | Falling green Matrix code. |
| `matrix-hallway.glsl` | 3D Matrix tunnel. |
| `cubes.glsl` | Rotating 3D cube field. |
| `gears-and-belts.glsl` | Rotating mechanical gears. |
| `fireworks.glsl` | Animated fireworks. |
| `fireworks-rockets.glsl` | Fireworks with launch trails. |
| `sparks-from-fire.glsl` | Drifting fire embers. |
| `smoke-and-ghost.glsl` | Wispy smoke. |

## Cursor / focus

| File | Effect |
|---|---|
| `cursor_blaze.glsl` | Cursor trail. Reference impl for `iCurrentCursor` / `iPreviousCursor` / `iTimeCursorChange`. |

## Combined stacks worth trying first

From catskull's recommendations:

```conf
# Wobbly CRT phosphor glow — comfy, readable
custom-shader = ~/.config/ghostty/shaders/drunkard.glsl
custom-shader = ~/.config/ghostty/shaders/retro-terminal.glsl
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
custom-shader-animation = true
```

```conf
# Signal-degraded chaos — fun, not for serious work
custom-shader = ~/.config/ghostty/shaders/glitchy.glsl
custom-shader = ~/.config/ghostty/shaders/bettercrt.glsl
custom-shader = ~/.config/ghostty/shaders/water.glsl
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
```

```conf
# Crisp TFT pixels behind a CRT curve — most-cited "wow"
custom-shader = ~/.config/ghostty/shaders/tft.glsl
custom-shader = ~/.config/ghostty/shaders/bettercrt.glsl
```

## Where to browse visuals

This library doesn't host screenshots — see:

- catskull's gallery: <https://catskull.net/fun-with-ghostty-shaders.html>
  (every shader with a video clip)
- The `README.md` and `screenshots/` folder in
  [hackr-sh/ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders).

## Other shader repos

From the [Awesome-Ghostty](https://github.com/fearlessgeekmedia/Awesome-Ghostty)
list:

- [`alex-sherwin/my-ghostty-shaders`](https://github.com/alex-sherwin/my-ghostty-shaders)
- [`fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty`](https://github.com/fearlessgeekmedia/Fearless-Geek-Shaders-for-Ghostty)
- [`luiscarlospando/crt-shader-with-chromatic-aberration-glow-scanlines-dot-matrix`](https://github.com/luiscarlospando/crt-shader-with-chromatic-aberration-glow-scanlines-dot-matrix)
  — single, very polished CRT shader.
- [`12jihan/ghostty_shaders`](https://github.com/12jihan/ghostty_shaders)
- [`erniee/gshaders`](https://github.com/erniee/gshaders)

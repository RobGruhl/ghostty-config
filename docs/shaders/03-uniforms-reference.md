---
title: Uniforms Reference
chapter: 3
source: ghostty-org/ghostty src/config/Config.zig (verbatim doc-comments)
---

# Uniforms Reference

The complete list of uniforms Ghostty exposes to custom shaders. Quoted
**verbatim** from `src/config/Config.zig` in the upstream `ghostty-org/ghostty`
repo. This is the authoritative source — anything else is hearsay.

## Entry point

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // your effect here
}
```

## Shadertoy-compatible uniforms

| Uniform | Type | Notes |
|---|---|---|
| `iChannel0` | `sampler2D` | The rendered terminal screen. With stacked shaders, this is the output of the previous shader. |
| `iResolution` | `vec3` | `[width, height, 1]` in pixels. |
| `iTime` | `float` | Seconds since first frame rendered. |
| `iTimeDelta` | `float` | Seconds since previous frame. |
| `iFrame` | `int` | Frames rendered so far. |
| `iChannelResolution[4]` | `vec3` | Resolutions of the 4 input samplers. Only `iChannelResolution[0]` is meaningful (== `iResolution`). |
| `iFrameRate` | `float` | **NOT CURRENTLY SUPPORTED.** |
| `iChannelTime[4]` | `float` | Time for video/audio input. **N/A.** |
| `iMouse` | `vec4` | Mouse info. **NOT CURRENTLY SUPPORTED.** |
| `iDate` | `vec4` | Date/time info. **NOT CURRENTLY SUPPORTED.** |
| `iSampleRate` | `float` | Audio sample rate. **N/A.** |

If you're porting a Shadertoy effect that relies on `iMouse` or `iDate`,
either stub them out or substitute another input (e.g. `iTime`-driven motion).

## Ghostty-specific extensions

These don't exist on Shadertoy — they're what makes a Ghostty shader a
*terminal* shader rather than a generic visualization.

### Cursor tracking

```glsl
vec4 iCurrentCursor;         // (x, y, w, h) — see below
vec4 iPreviousCursor;        // previous cursor (for smooth animation)
vec4 iCurrentCursorColor;    // RGBA
vec4 iPreviousCursorColor;
vec4 iCurrentCursorStyle;    // see macros below
vec4 iPreviousCursorStyle;
vec4 iCursorVisible;         // visibility
float iTimeCursorChange;     // iTime when cursor last changed
```

`iCurrentCursor` semantics (verbatim from Config.zig):

> - `iCurrentCursor.xy` is the -X, +Y corner of the current cursor.
> - `iCurrentCursor.zw` is the width and height of the current cursor.

`iCurrentCursorStyle` uses predefined macros:

```glsl
CURSORSTYLE_BLOCK         // 0
CURSORSTYLE_BLOCK_HOLLOW  // 1
CURSORSTYLE_BAR           // 2
CURSORSTYLE_UNDERLINE     // 3
CURSORSTYLE_LOCK          // 4
```

`iTimeCursorChange` semantics:

> When the terminal cursor changes position or color, this is set to the same
> time as the `iTime` uniform, allowing you to compute the time since the
> change by subtracting this from `iTime`.

Classic use: cursor trail / blaze / smear effects. See `cursor_blaze.glsl` in
the community pack.

### Focus state

```glsl
int   iFocus;       // 1 when focused, 0 when unfocused
float iTimeFocus;   // iTime when surface last gained focus
```

From Config.zig on `iFocus`:

> Set to 1.0 when the surface is focused, 0.0 when unfocused. This allows
> shaders to detect unfocused state and avoid animation artifacts from large
> time deltas caused by infrequent "deceptive frames" (e.g., modifier key
> presses, link hover events in unfocused split panes).
> Check `iFocus > 0` to determine if the surface is currently focused.

On `iTimeFocus`:

> When the surface gains focus, this is set to the current value of `iTime`,
> similar to how `iTimeCursorChange` works. This allows you to compute the
> time since focus was gained or lost by calculating `iTime - iTimeFocus`.
> Use this to create animations that restart when the terminal regains focus.

Full focus patterns in [chapter 4](04-focus-aware.md).

### Terminal palette & semantic colors

```glsl
vec3 iPalette[256];               // full 256-color palette, RGB ∈ [0,1]
vec3 iBackgroundColor;
vec3 iForegroundColor;
vec3 iCursorColor;
vec3 iCursorText;
vec3 iSelectionBackgroundColor;
vec3 iSelectionForegroundColor;
```

From Config.zig on `iPalette`:

> RGB values for all 256 colors in the terminal palette, normalized to
> [0.0, 1.0]. Index 0-15 are the ANSI colors, 16-231 are the 6x6x6 color
> cube, and 232-255 are the grayscale colors.

These are gold for theme-coherent effects:

- Tint your bloom by `iForegroundColor` so glow always harmonizes with text.
- Pick particle / spark colors from `iPalette[i]` to match the user's theme.
- Compute a dimmed version of `iBackgroundColor` for unfocused fades.

## Minimal passthrough shader

If you just want to confirm the pipeline:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}
```

Save as `~/.config/ghostty/shaders/passthrough.glsl`, add
`custom-shader = ~/.config/ghostty/shaders/passthrough.glsl` to your config.
If the terminal looks unchanged, the pipeline works.

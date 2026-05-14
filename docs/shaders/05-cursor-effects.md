---
title: Cursor Effects
chapter: 5
---

# Cursor Effects

Ghostty exposes the current and previous cursor (position, size, color,
style, visibility) plus a timestamp of the last change, enabling smooth
trail/blaze/pulse animations tied to caret motion. These uniforms are
Ghostty-specific extensions on top of the Shadertoy interface.

## The uniforms (recap)

```glsl
vec4  iCurrentCursor;        // (x, y, w, h) — see semantics below
vec4  iPreviousCursor;
vec4  iCurrentCursorColor;   // RGBA
vec4  iPreviousCursorColor;
vec4  iCurrentCursorStyle;   // use CURSORSTYLE_* macros
vec4  iPreviousCursorStyle;
vec4  iCursorVisible;
float iTimeCursorChange;     // iTime when cursor last moved/changed color
```

Style macros (predefined for you):

| Macro | Value |
|---|---|
| `CURSORSTYLE_BLOCK` | 0 |
| `CURSORSTYLE_BLOCK_HOLLOW` | 1 |
| `CURSORSTYLE_BAR` | 2 |
| `CURSORSTYLE_UNDERLINE` | 3 |
| `CURSORSTYLE_LOCK` | 4 |

## Cursor position semantics

Verbatim from Config.zig:

> - `iCurrentCursor.xy` is the -X, +Y corner of the current cursor.
> - `iCurrentCursor.zw` is the width and height of the current cursor.

That `-X, +Y` corner is the **top-left in screen pixels** (Y increases
upward in the shader-coordinate convention Ghostty uses, but the corner being
referred to is the upper-left visually). When in doubt, sanity-check by
rendering a small dot at `iCurrentCursor.xy / iResolution.xy` in the
passthrough shader.

## Pattern 1 — cursor halo

Drop a soft glow around the cursor's current position:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    // cursor center in pixel space
    vec2 cur = iCurrentCursor.xy + 0.5 * iCurrentCursor.zw;
    float d = distance(fragCoord, cur);

    // soft halo
    float halo = exp(-d * d / (60.0 * 60.0));
    fragColor = vec4(c.rgb + iCurrentCursorColor.rgb * halo * 0.6, c.a);
}
```

## Pattern 2 — cursor trail / "blaze"

Animate a streak between the previous and current cursor position. The
community `cursor_blaze.glsl` in `hackr-sh/ghostty-shaders` is the reference
implementation — read it for inspiration. The skeleton:

```glsl
const float TRAIL_DURATION = 0.25;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    float t = iTime - iTimeCursorChange;
    if (t > TRAIL_DURATION) { fragColor = c; return; }

    // Animate cursor center from previous → current over TRAIL_DURATION
    vec2 prev = iPreviousCursor.xy + 0.5 * iPreviousCursor.zw;
    vec2 cur  = iCurrentCursor.xy  + 0.5 * iCurrentCursor.zw;
    float k = t / TRAIL_DURATION;                  // 0 → 1
    vec2 head = mix(prev, cur, smoothstep(0.0, 1.0, k));

    // Distance from this pixel to the moving segment prev → head
    vec2 ab = head - prev;
    float h = clamp(dot(fragCoord - prev, ab) / max(dot(ab, ab), 1e-3), 0.0, 1.0);
    float d = distance(fragCoord, prev + ab * h);

    float strength = (1.0 - k) * exp(-d / 18.0);
    fragColor = vec4(c.rgb + iCurrentCursorColor.rgb * strength, c.a);
}
```

## Pattern 3 — style-conditional effect

Apply a different visual treatment depending on the cursor style — e.g. only
draw a halo for `CURSORSTYLE_BLOCK`:

```glsl
if (int(iCurrentCursorStyle.x) == CURSORSTYLE_BLOCK) {
    // halo code here
}
```

`int(iCurrentCursorStyle.x)` is the conventional way to read the style value
since the uniform is declared `vec4`.

## Pattern 4 — hide on invisible

Respect `iCursorVisible` so effects don't render when the user has hidden the
cursor (e.g., during `tput civis`):

```glsl
if (iCursorVisible.x < 0.5) { fragColor = c; return; }
```

## Gotchas

- `iCurrentCursor` and `iPreviousCursor` are updated whenever the cursor moves
  *or* changes color/style. Use `iTimeCursorChange` to gate animation duration
  uniformly instead of trying to detect motion yourself.
- For multi-line moves (e.g. line wraps), the straight-line interpolation
  between `iPreviousCursor` and `iCurrentCursor` will visually "cut through"
  text. Cursor-trail shaders typically just accept this — it looks fine.
- Cursor uniforms are present in current 1.x development builds. If you're on
  an older release and they read zero, update Ghostty.

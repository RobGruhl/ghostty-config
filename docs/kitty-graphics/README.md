---
title: Kitty Graphics in Ghostty 1.4 — a Claude Code showcase
updated: 2026-10-28
ghostty: 1.4.0
---

# Kitty graphics in Ghostty 1.4: what Claude Code can do with it

Ghostty 1.4 finished the Kitty graphics protocol. It adds **animation** (frame transmission, composition, playback control) and **relative placements** (an image placement anchored to another one), plus a conformance pass and SIMD payload parsing. PRs: #13943 #13939 #13935 #13934 #13893 #13933 #13389 #13270 #13281.

This folder turns that into something you can run. There are three standalone demos that exercise the new features directly, and a working Claude Code mod that draws images inside Claude Code's own UI. Everything here was run and screenshotted in Ghostty 1.4.0 on 2026-10-28.

## The one idea that matters

Before 1.4, an animated image in a terminal meant a live process re-sending pixels every frame. Now a program uploads its frames **once** and the terminal plays them. Playback costs the program nothing, keeps running after the program exits, and pauses while the tab isn't visible.

For Claude Code, that means status visuals (an activity orb, a spinner on a subagent card, a gauge) can be fire-and-forget. Nothing has to stay alive to animate them.

## Where pixels can reach in Claude Code

| Path | What works | Status |
| --- | --- | --- |
| **A mod's `Image` element** (pane, band above the prompt) | PNG or RGBA bytes, or a file or POSIX shared-memory name the terminal reads itself. Drawn with Kitty graphics on Ghostty and kitty. `$.ui.blit` swaps a keyed Image's source at the frame rate (up to ~60 shown/s). A `Raster` element draws grids of colored cells. | **Works today.** See [`mod/kitty-showcase`](mod/kitty-showcase/) |
| **A program in a Ghostty split, tab or quick terminal** beside Claude Code | The whole protocol: native animation, relative placements, composition | **Works today.** See the demos below |
| Bash tool output, `!` commands, hook stdout | Captured as text and redrawn by Claude Code. Raw escape sequences don't reach Ghostty. | Not a route for images |
| Status line command | Its stdout is drawn by Claude Code's renderer | Untested. Assume escapes are stripped; use a mod's `$.ui.status` plus a band instead |

The mod API doesn't expose native animation or relative placements today. `Image` takes one picture, so a mod animates by blitting each frame. See the [wishlist](#wishlist-for-the-mod-api) for what that would take.

## Run the demos

These are plain Python 3 with no dependencies. Run them directly in a Ghostty window: not through a pipe, and not inside tmux.

```bash
cd docs/kitty-graphics/examples
python3 orb.py            # "Thinking…" orb: 32 frames uploaded once, Ghostty loops them, script exits
python3 orb.py --tool     # same in gold, the "running a tool" state
python3 orb.py --clear    # remove the orbs
python3 fleet.py          # subagent board on relative placements (alt screen; Enter to exit)
python3 gauge.py          # context ring: 21 states as partial frames, switched with one tiny escape each
```

| Demo | 1.4 feature | What to watch |
| --- | --- | --- |
| [`orb.py`](examples/orb.py) | Frame transmission (`a=f`) + playback (`a=a,s=3`) | The caption says "this process has exited", and the light keeps circling the orb. Switch tabs and back: playback pauses while the tab is hidden. |
| [`fleet.py`](examples/fleet.py) | Relative placements (`P`,`Q`,`H`,`V`) | Each card is a parent placement. Its spinner badge and shimmer strip are animated children. The script reorders the cards by re-sending **only the parents**, and the children follow, still animating. Then it swaps one badge for a check mark and deletes a parent: its children go with it. |
| [`gauge.py`](examples/gauge.py) | Partial frames (`x,y,s,v` + base `c`) and frame jumps (`a=a,c=N`) | Animation frames used as a sprite sheet. Each frame carries only the rectangle that changed since the previous one. Moving the needle sends a ~30-byte escape and no pixels. |

[`kgfx.py`](examples/kgfx.py) is the ~150-line protocol writer the demos share: transmit, place (including relative), frames, playback, frame jumps, delete, and chunking.

## The mod: `kitty-showcase`

A Claude Code pane drawn with Kitty graphics. Run `/kitty-showcase` to open it.

- **Activity orb.** The same sphere as `orb.py`, rendered once per mode in the mod and swapped with `$.ui.blit` at ~15 fps. Idle is a slow muted breathe. Thinking (after a prompt is submitted) is iris. Running a tool is gold, with the tool's name.
- **Context ring.** The same ring as `gauge.py`, filled from `$.session.usage().context.percent`. It's redrawn after each tool call and each turn.
- **Fallback.** On desktop, VS Code and mobile the pane draws the captions as text.

Source: [`mod/kitty-showcase/`](mod/kitty-showcase/). The live copy that Claude Code loads during development is `~/.claude/dev-mods/<session>/kitty-showcase/`. To load the repo copy in any session, run `claude --plugin-dir docs/kitty-graphics/mod/kitty-showcase`. Check it with `claude plugin validate` and `claude plugin test` (2 tests).

## Idea catalog

These are grouped by what they'd use. ✅ = built here, 🟢 = possible today with the mod API, 🟡 = needs native animation or relative placements in the mod API, or a sidecar program in a split.

**Ambient session state**

- ✅ Activity orb: idle, thinking, or running a tool (mod + `orb.py`).
- ✅ Context-window ring, foam → gold → love as it fills (mod + `gauge.py`).
- 🟢 Rate-limit rings for the 5-hour and 7-day windows from `$.session.usage().rateLimits`, with a tick at elapsed-time-through-window so you can see whether you're on pace.
- 🟢 A cost and duration sparkline for the turn, as a `Raster` (cells, not pixels: cheap and crisp).

**Agents and work**

- ✅ Subagent fleet board: one card per agent, with a status badge and progress strip riding on each card (`fleet.py`).
- 🟢 The same board in a pane: one keyed `Image` per agent, blitting a spinner. Ink does the layout, so relative placements matter less inside Claude Code than in a raw TUI.
- 🟢 A codex-fleet run board: a cell per worker, colored by pass/fail from `.fleet/run-N/summary.json`.
- 🟢 A session edits heat map: each touched file is a tile, hotter with more lines changed.

**Seeing what the model sees**

- 🟢 Live screenshot pane for browser work (Playwright or Chrome tools). `ImageSource` takes a shared-memory name, so frames never pass through the mod. The API's own example of this is a browser view.
- 🟢 Blender viewport pane: the Blender MCP's `look` renders, shown as they arrive.
- 🟢 Thumbnails of images the model just `Read`, pinned in a pane so you see what it saw.
- 🟢 A Terraria autopilot live view while `autopilot-driver` runs.
- 🟢 Rendered diagrams (Mermaid or Graphviz to PNG) for architecture answers, in a pane instead of ASCII.
- 🟢 Shader previews for `docs/shaders`: render a frame of a `.glsl` offscreen and show it before you install it.

**Native-animation niceties (🟡 in the mod API, ✅ in a split)**

- Zero-traffic spinners: upload once and let Ghostty loop them, instead of a blit every 66 ms.
- Animations that pause for free when the tab or pane is hidden.
- Badges anchored to a thumbnail (relative placement): "new", "failed", "3 comments".

## Wishlist for the mod API

What would bring the 1.4 features into mods:

1. **An animated `ImageSource`**, e.g. `{ frames: [{ rgba, gapMs }], loop }`. The engine uploads with `a=f` once, and Ghostty plays it with no blits. It pauses when hidden, and the terminal gets one upload instead of ~15 commands a second.
2. **Frame control on a keyed Image**, e.g. `$.ui.blit({ key, frame: n })` mapping to `a=a,c=n`. This is the sprite-sheet trick from `gauge.py`.
3. **Child images**, so a mod can pin a badge to an `Image` via relative placement.

## Protocol notes (what bit while building this)

- **The root frame has no gap.** Frames added with `a=f` default to 40 ms, but frame 1 defaults to 0 until you send `a=a,r=1,z=<ms>`. Without it, the animation stutters on frame 1.
- **Loop count is off by one by design.** `v=1` loops forever, and `v=N` plays N-1 loops.
- **Chunked frames repeat `a=f`.** Later chunks carry only `m` (and `q`), except frame data, which must also carry `a=f`.
- **Relative placements can't be virtual.** A Unicode-placeholder placement (`U=1`, which is what Claude Code's `Image` uses) can be a parent but not a child. Chains go at least 8 deep, and deleting a parent deletes its children.
- **Re-sending `a=p` with the same `i` and `p` moves the placement.** That's how `fleet.py` reorders cards without touching their children.
- **Minimum contrast doesn't see images.** Ghostty's `minimum-contrast` compares text against the cell background, not the pixels under it. Light text on a dark image card, on a light theme, gets darkened into illegibility. Fix: give those cells a background color matching the image (the image hides it). See `label()` in `fleet.py`.
- **Text over images.** `z=-1` draws the image under text and over cell backgrounds. Below `-1073741824` it also goes under non-default cell backgrounds.
- **Quiet mode.** Send `q=2`, or the terminal's OK and error replies arrive on stdin and land on your prompt.
- **tmux** drops all of this unless `allow-passthrough` is on (and the program wraps the sequences). Claude Code's `Image` handles tmux itself when `allow-passthrough` and `focus-events` are on.

## Sources

- Kitty graphics protocol spec: https://sw.kovidgoyal.net/kitty/graphics-protocol/ (Animation, Relative placements, Unicode placeholders)
- Ghostty 1.4 release notes, "Kitty Graphics Animation and Relative Placements"
- Claude Code mod API: `ImageProps`, `ImageSource`, `$.ui.blit` and `RasterProps` in the engine's `claude-code.d.ts` (Claude Code 2.1.312)
- Palette: Rosé Pine (https://rosepinetheme.com), matching this setup's Ghostty and Claude Code themes

#!/usr/bin/env python3
"""A "Claude is thinking" orb that the terminal animates by itself.

Uploads 32 frames once, tells Ghostty to loop them, prints a caption, and
EXITS. The orb keeps turning after the process is gone: playback runs inside
the terminal, costs the program nothing, and pauses while the tab is hidden.

That is the new thing in Ghostty 1.4. Before, a program had to stay alive and
re-send pixels every frame (which is what a Claude Code mod's $.ui.blit does).

    python3 docs/kitty-graphics/examples/orb.py            # thinking (iris)
    python3 docs/kitty-graphics/examples/orb.py --tool     # tool running (gold)
    python3 docs/kitty-graphics/examples/orb.py --clear    # remove every orb
"""

import math
import sys

import kgfx as k

SIZE = 96
FRAMES = 32
GAP_MS = 45
COLS, ROWS = 10, 5  # roughly square on a 1:2 cell


def orb_frame(t, body, glow):
    """One frame: a lit sphere with a light circling it and a breathing halo."""
    radius = 0.52
    theta = t * k.TAU
    light = (math.cos(theta) * 0.75, math.sin(theta) * 0.45 - 0.25, 0.6)
    n = math.sqrt(sum(c * c for c in light))
    light = tuple(c / n for c in light)
    breathe = 0.5 + 0.5 * math.sin(theta * 2)
    dark = k.rgb01(k.ROSE_PINE["overlay"])
    body = k.rgb01(body)
    glow = k.rgb01(glow)
    gold = k.rgb01(k.ROSE_PINE["gold"])

    def shade(x, y):
        u = (x + 0.5) / SIZE * 2 - 1
        v = (y + 0.5) / SIZE * 2 - 1
        d = math.hypot(u, v)
        halo = math.exp(-max(0.0, d - radius) / (0.10 + 0.05 * breathe)) * (0.35 + 0.35 * breathe)
        if d >= radius:
            return (*glow, halo * (1 - k.smoothstep(0.9, 1.0, d)))
        nz = math.sqrt(max(0.0, 1 - (d / radius) ** 2))
        normal = (u / radius, v / radius, nz)
        diffuse = max(0.0, sum(a * b for a, b in zip(normal, light)))
        spec = max(0.0, 2 * diffuse * normal[2] - light[2]) ** 24
        r, g, b = k.mix(dark, body, 0.25 + 0.75 * diffuse)
        r, g, b = k.mix((r, g, b), gold, spec * 0.8)
        edge = k.smoothstep(radius, radius - 0.03, d)  # antialiased rim, blended into the halo
        a = edge + (1 - edge) * halo
        return (r, g, b, a)

    return k.render(SIZE, SIZE, shade)


def main():
    k.require_kitty_graphics()
    if "--clear" in sys.argv:
        for image_id in (101, 102):
            k.delete(image_id)
        k.flush()
        return

    is_tool = "--tool" in sys.argv
    image_id = 102 if is_tool else 101
    body = k.ROSE_PINE["gold"] if is_tool else k.ROSE_PINE["iris"]
    glow = k.ROSE_PINE["rose"] if is_tool else k.ROSE_PINE["iris"]
    caption = ("Running Bash", "frames uploaded once · the terminal loops them") if is_tool else (
        "Thinking…",
        "frames uploaded once · the terminal loops them",
    )

    print(f"rendering {FRAMES} frames…", end="\r", file=sys.stderr, flush=True)
    frames = [orb_frame(i / FRAMES, body, glow) for i in range(FRAMES)]
    print(" " * 30, end="\r", file=sys.stderr, flush=True)

    k.delete(image_id)  # re-running replaces the old orb instead of stacking
    k.transmit(image_id, frames[0], SIZE, SIZE)
    for f in frames[1:]:
        k.add_frame(image_id, f, SIZE, SIZE, gap_ms=GAP_MS)
    k.set_gap(image_id, 1, GAP_MS)  # the root frame has no gap until set

    # Reserve ROWS lines, go back up, drop the orb at the cursor, write the caption beside it.
    sys.stdout.write("\n" * ROWS + f"\x1b[{ROWS}A")
    k.place(image_id, cols=COLS, rows=ROWS)
    sys.stdout.write(f"\x1b[1B\x1b[{COLS + 2}C\x1b[1m{caption[0]}\x1b[0m")
    sys.stdout.write(f"\r\x1b[1B\x1b[{COLS + 2}C\x1b[2m{caption[1]}\x1b[0m")
    sys.stdout.write(f"\r\x1b[1B\x1b[{COLS + 2}C\x1b[2mthis process has exited\x1b[0m")
    sys.stdout.write(f"\r\x1b[{ROWS - 3}B")
    k.play(image_id)
    k.flush()


if __name__ == "__main__":
    main()

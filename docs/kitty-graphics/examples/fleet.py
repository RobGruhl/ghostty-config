#!/usr/bin/env python3
"""A subagent "fleet" board built on relative placements.

Each agent is a card (the parent placement). Two children ride on it: a
spinning status badge and a shimmering progress strip, both animated by the
terminal itself. The script then:

  1. reorders the cards by moving ONLY the parents; the children follow,
     still animating, without the script ever touching them again;
  2. marks one agent done by swapping its badge child for a check mark;
  3. dismisses a card by deleting its parent; its children go with it.

Runs on the alternate screen and restores your terminal when you press Enter.

    python3 docs/kitty-graphics/examples/fleet.py
    python3 docs/kitty-graphics/examples/fleet.py --hold 20   # no Enter; exit after 20s
"""

import math
import sys
import time

import kgfx as k

CARD, BADGE, STRIP, CHECK = 201, 202, 203, 204
CARD_COLS, CARD_ROWS = 44, 3
LEFT = 4
SLOT = CARD_ROWS + 1  # rows from one card's top to the next

AGENTS = [
    ("explore", "searching docs/ for Kitty", k.ROSE_PINE["foam"]),
    ("verify", "running tests (3 of 8)", k.ROSE_PINE["gold"]),
    ("review", "reading the diff", k.ROSE_PINE["iris"]),
]


def move(row, col=1):
    sys.stdout.write(f"\x1b[{row};{col}H")


def card_pixels():
    w, h = 440, 60
    top = k.rgb01(k.ROSE_PINE["overlay"])
    bottom = k.rgb01(k.ROSE_PINE["surface"])
    accent = k.rgb01(k.ROSE_PINE["iris"])
    radius = 10

    def shade(x, y):
        # rounded-rect mask
        dx = max(radius - x, 0, x - (w - 1 - radius))
        dy = max(radius - y, 0, y - (h - 1 - radius))
        a = 1 - k.smoothstep(radius - 1, radius, math.hypot(dx, dy))
        r, g, b = k.mix(top, bottom, y / h)
        if x < 4:
            r, g, b = accent
        return (r, g, b, a)

    return k.render(w, h, shade), w, h


def badge_frames(n=12, size=32):
    ring = k.rgb01(k.ROSE_PINE["iris"])
    dim = k.rgb01(k.ROSE_PINE["muted"])
    frames = []
    for i in range(n):
        head = i / n * k.TAU

        def shade(x, y, head=head):
            u, v = (x + 0.5) / size * 2 - 1, (y + 0.5) / size * 2 - 1
            d = math.hypot(u, v)
            band = k.smoothstep(0.55, 0.62, d) * (1 - k.smoothstep(0.86, 0.93, d))
            ang = (math.atan2(v, u) - head) % k.TAU
            tail = max(0.0, 1 - ang / (k.TAU * 0.7))  # comet tail behind the head
            r, g, b = k.mix(dim, ring, tail)
            return (r, g, b, band * (0.25 + 0.75 * tail))

        frames.append(k.render(size, size, shade))
    return frames, size


def strip_frames(n=16, w=360, h=8):
    base = k.rgb01(k.ROSE_PINE["muted"])
    hi = k.rgb01(k.ROSE_PINE["rose"])
    frames = []
    for i in range(n):
        center = i / n * 1.6 - 0.3

        def shade(x, y, center=center):
            t = x / w
            glow = math.exp(-(((t - center) / 0.12) ** 2))
            r, g, b = k.mix(base, hi, glow)
            return (r, g, b, (0.25 + 0.65 * glow) * (1 - abs(y - h / 2) / (h / 2)) ** 0.5)

        frames.append(k.render(w, h, shade))
    return frames, w, h


def check_pixels(size=32):
    green = k.rgb01(k.ROSE_PINE["foam"])

    def seg(px, py, ax, ay, bx, by):
        vx, vy = bx - ax, by - ay
        t = max(0, min(1, ((px - ax) * vx + (py - ay) * vy) / (vx * vx + vy * vy)))
        return math.hypot(px - ax - t * vx, py - ay - t * vy)

    def shade(x, y):
        u, v = (x + 0.5) / size, (y + 0.5) / size
        d = min(seg(u, v, 0.22, 0.52, 0.42, 0.72), seg(u, v, 0.42, 0.72, 0.80, 0.30))
        return (*green, 1 - k.smoothstep(0.05, 0.08, d))

    return k.render(size, size, shade), size


def upload_animation(image_id, frames, w, h, gap):
    k.transmit(image_id, frames[0], w, h)
    for f in frames[1:]:
        k.add_frame(image_id, f, w, h, gap_ms=gap)
    k.set_gap(image_id, 1, gap)
    k.play(image_id)


CARD_BG = "\x1b[48;2;38;35;58m"  # the card's own color under its text, see label()
TASK_W = CARD_COLS - 15  # stops short of the badge child


def label(row, name, task, color, status=""):
    """Card text is ordinary terminal text drawn over the card image (z=-1).

    The cells also get the card's color as their background. The image hides
    it, but Ghostty's minimum-contrast check reads cell colors, not pixels:
    without it, light text over a dark card on a light theme gets darkened.
    """
    r, g, b = color
    move(row + 1, LEFT + 2)
    sys.stdout.write(
        f"{CARD_BG}\x1b[1;38;2;{r};{g};{b}m{name:<8}\x1b[22;38;2;224;222;244m {task[:TASK_W]:<{TASK_W}}\x1b[0m"
    )
    if status:  # the progress strip child sits on this row while the agent runs
        move(row + 2, LEFT + 2)
        sys.stdout.write(f"{CARD_BG}\x1b[38;2;144;140;170m{status[: TASK_W + 9]:<{TASK_W + 9}}\x1b[0m")


def blank(row):
    for dy in range(CARD_ROWS):
        move(row + dy, LEFT)
        sys.stdout.write(" " * (CARD_COLS + 2))


def place_card(slot_id, row):
    """Move (or first place) a card. Only the parent is ever re-sent."""
    move(row, LEFT)
    k.place(CARD, placement_id=slot_id, cols=CARD_COLS, rows=CARD_ROWS, z=-1)


def attach_children(slot_id):
    parent = (CARD, slot_id)
    k.place(BADGE, placement_id=slot_id, cols=3, rows=1, parent=parent, offset=(CARD_COLS - 4, 1))
    k.place(STRIP, placement_id=slot_id, cols=CARD_COLS - 6, rows=1, parent=parent, offset=(2, 2), z=1)


def main():
    k.require_kitty_graphics()
    hold = None
    if "--hold" in sys.argv:
        hold = float(sys.argv[sys.argv.index("--hold") + 1])

    card, cw, ch = card_pixels()
    badges, bs = badge_frames()
    strips, sw, sh = strip_frames()
    check, cs = check_pixels()

    sys.stdout.write("\x1b[?1049h\x1b[?25l\x1b[2J")
    move(1, LEFT)
    sys.stdout.write("\x1b[1mSubagents\x1b[0m  \x1b[2mrelative placements · Ghostty 1.4\x1b[0m")

    k.transmit(CARD, card, cw, ch)
    upload_animation(BADGE, badges, bs, bs, 60)
    upload_animation(STRIP, strips, sw, sh, 70)
    k.transmit(CHECK, check, cs, cs)

    rows = {i + 1: 3 + i * SLOT for i in range(len(AGENTS))}
    for slot_id, (name, task, color) in enumerate(AGENTS, start=1):
        place_card(slot_id, rows[slot_id])
        attach_children(slot_id)
        label(rows[slot_id], name, task, color)

    def caption(text):
        move(3 + len(AGENTS) * SLOT + 1, LEFT)
        sys.stdout.write(f"\x1b[2K\x1b[2m{text}\x1b[0m")
        k.flush()

    caption("three cards; each badge and strip is a child of its card")
    time.sleep(2.5)

    # 1. Swap the first and last cards by moving only the parents.
    caption("reordering: only the two parent cards are re-sent; children follow")
    a, c = 1, 3
    start_a, start_c = rows[a], rows[c]
    steps = start_c - start_a
    for s in range(1, steps + 1):
        blank(rows[a]); blank(rows[c])
        rows[a], rows[c] = start_a + s, start_c - s
        place_card(a, rows[a]); place_card(c, rows[c])
        label(rows[2], *AGENTS[1])
        label(rows[c], *AGENTS[c - 1]); label(rows[a], *AGENTS[a - 1])
        k.flush()
        time.sleep(0.09)
    time.sleep(1.5)

    # 2. "verify" finishes: replace its badge child, stop its strip.
    caption("verify finished: its badge child swapped for a check mark")
    k.cmd({"a": "d", "d": "i", "i": BADGE, "p": 2})
    k.cmd({"a": "d", "d": "i", "i": STRIP, "p": 2})
    k.place(CHECK, placement_id=2, cols=3, rows=1, parent=(CARD, 2), offset=(CARD_COLS - 4, 1))
    label(rows[2], "verify", "8 of 8 tests passed", AGENTS[1][2], "done in 41s")
    k.flush()
    time.sleep(2.5)

    # 3. Dismiss it: delete only the parent. Its check-mark child goes with it.
    caption("dismissed: deleting the parent card took its children with it")
    k.cmd({"a": "d", "d": "i", "i": CARD, "p": 2})
    blank(rows[2])
    k.flush()

    if hold is not None:
        time.sleep(hold)
    else:
        caption("press Enter to exit")
        input()
    k.cmd({"a": "d", "d": "A"})
    sys.stdout.write("\x1b[?25h\x1b[?1049l")
    k.flush()


if __name__ == "__main__":
    main()

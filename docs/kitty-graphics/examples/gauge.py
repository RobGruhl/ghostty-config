#!/usr/bin/env python3
"""A context-window gauge whose every state is a frame, uploaded once.

Animation frames double as a sprite sheet. The script uploads 21 gauge states
(0%, 5%, … 100%) as frames of one image with playback stopped, then moves
the needle by jumping to a frame (a=a,c=N): one ~30-byte escape per update,
no pixels. That's the cheap way for a status line or a long-running helper
to show live state.

Frames are also partial: each one starts from the previous frame (c=N-1) and
carries only the rectangle that changed, so the upload is a fraction of 21
full images. The script prints the byte count at the end.

    python3 docs/kitty-graphics/examples/gauge.py
"""

import math
import sys
import time
import zlib

import kgfx as k

GAUGE = 301
SIZE = 72
STEPS = 21  # frame N shows (N-1)*5 %
COLS, ROWS = 8, 4


def ring(pct):
    track = k.rgb01(k.ROSE_PINE["overlay"])
    ramp = [k.rgb01(k.ROSE_PINE[c]) for c in ("foam", "gold", "love")]
    fill_to = pct / 100 * k.TAU
    color = k.mix(ramp[0], ramp[1], min(1, pct / 60)) if pct <= 60 else k.mix(ramp[1], ramp[2], (pct - 60) / 40)

    def shade(x, y):
        u, v = (x + 0.5) / SIZE * 2 - 1, (y + 0.5) / SIZE * 2 - 1
        d = math.hypot(u, v)
        band = k.smoothstep(0.62, 0.66, d) * (1 - k.smoothstep(0.90, 0.94, d))
        ang = (math.atan2(u, -v)) % k.TAU  # 0 at 12 o'clock, clockwise
        r, g, b = color if ang <= fill_to and pct > 0 else track
        return (r, g, b, band)

    return k.render(SIZE, SIZE, shade)


def changed_rect(a, b):
    """Bounding box (x, y, w, h) of pixels that differ between two RGBA frames."""
    xs, ys = [], []
    for y in range(SIZE):
        row = y * SIZE * 4
        if a[row : row + SIZE * 4] == b[row : row + SIZE * 4]:
            continue
        ys.append(y)
        for x in range(SIZE):
            i = row + x * 4
            if a[i : i + 4] != b[i : i + 4]:
                xs.append(x)
    if not ys:
        return 0, 0, 1, 1
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def crop(px, x, y, w, h):
    out = bytearray()
    for row in range(y, y + h):
        start = (row * SIZE + x) * 4
        out += px[start : start + w * 4]
    return bytes(out)


def main():
    k.require_kitty_graphics()
    frames = [ring(i * 5) for i in range(STEPS)]

    k.delete(GAUGE)
    k.transmit(GAUGE, frames[0], SIZE, SIZE)
    sent = len(zlib.compress(frames[0], 6))
    for n in range(1, STEPS):
        x, y, w, h = changed_rect(frames[n - 1], frames[n])
        patch = crop(frames[n], x, y, w, h)
        # Frame n+1 = frame n with just this rectangle replaced.
        k.add_frame(GAUGE, patch, w, h, x=x, y=y, base=n, replace=True)
        sent += len(zlib.compress(patch, 6))
    full = sum(len(zlib.compress(f, 6)) for f in frames)

    sys.stdout.write("\x1b[?25l" + "\n" * ROWS + f"\x1b[{ROWS}A")  # hide the cursor while the needle moves
    k.place(GAUGE, cols=COLS, rows=ROWS)

    def readout(pct, note):
        sys.stdout.write(f"\x1b7\x1b[1B\x1b[{COLS + 2}C\x1b[1mcontext {pct:>3}%\x1b[0m")
        sys.stdout.write(f"\r\x1b[1B\x1b[{COLS + 2}C\x1b[2m{note:<40}\x1b[0m\x1b8")
        k.flush()

    # A session filling up, then /compact.
    timeline = [(p, "one tiny escape per update, no pixels") for p in range(5, 96, 3)]
    timeline += [(22, "compacted")]
    for pct, note in timeline:
        k.show_frame(GAUGE, round(pct / 5) + 1)
        readout(pct, note)
        time.sleep(0.12 if note != "compacted" else 0)

    sys.stdout.write(f"\x1b[{ROWS}B\r\x1b[?25h")
    print(f"\x1b[2muploaded {STEPS} states as partial frames: {sent:,} bytes compressed vs {full:,} as full frames\x1b[0m")
    k.flush()


if __name__ == "__main__":
    main()

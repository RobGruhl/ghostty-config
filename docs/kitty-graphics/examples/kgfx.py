"""Minimal Kitty graphics protocol writer (stdlib only).

Just enough of the spec to drive the Ghostty 1.4 demos in this folder:
transmit, place (incl. relative placements), animation frames, animation
control, and delete. Everything writes to stdout, so run the demos directly
in a Ghostty window (not through a pipe, not inside tmux).

Spec: https://sw.kovidgoyal.net/kitty/graphics-protocol/
"""

import base64
import math
import os
import sys
import zlib

ESC = "\x1b"
CHUNK = 4096  # max base64 bytes per escape; every chunk but the last is a multiple of 4


def _write(s):
    sys.stdout.write(s)


def flush():
    sys.stdout.flush()


def cmd(keys, payload=b"", compress=True):
    """Send one graphics command, chunking the payload per the spec.

    Only the first chunk carries the control keys; later chunks carry m=
    (and a=f when the command is a frame, which the spec requires).
    """
    keys = dict(keys)
    keys.setdefault("q", 2)  # suppress OK/error replies so they don't land on the prompt
    if payload and compress:
        payload = zlib.compress(payload, 6)
        keys["o"] = "z"
    data = base64.standard_b64encode(payload).decode("ascii") if payload else ""
    head = ",".join(f"{k}={v}" for k, v in keys.items())
    if len(data) <= CHUNK:
        _write(f"{ESC}_G{head};{data}{ESC}\\")
        return
    extra = ",a=f" if keys.get("a") == "f" else ""
    for i in range(0, len(data), CHUNK):
        part = data[i : i + CHUNK]
        more = 1 if i + CHUNK < len(data) else 0
        if i == 0:
            _write(f"{ESC}_G{head},m={more};{part}{ESC}\\")
        else:
            _write(f"{ESC}_Gm={more}{extra},q=2;{part}{ESC}\\")


# --- images -----------------------------------------------------------------


def transmit(image_id, rgba, w, h):
    """Upload RGBA pixels as image `image_id` (frame 1, the root frame). Nothing is shown yet."""
    cmd({"a": "t", "f": 32, "s": w, "v": h, "i": image_id}, rgba)


def place(image_id, placement_id=1, cols=None, rows=None, z=None, parent=None, offset=(0, 0)):
    """Show an image at the cursor, or relative to a parent placement.

    parent=(image_id, placement_id) makes this a relative placement: it sits
    offset=(H, V) cells from the parent's top-left and moves/deletes with it.
    Re-sending the same (image_id, placement_id) moves the existing placement.
    """
    keys = {"a": "p", "i": image_id, "p": placement_id, "C": 1}
    if cols:
        keys["c"] = cols
    if rows:
        keys["r"] = rows
    if z is not None:
        keys["z"] = z
    if parent:
        keys["P"], keys["Q"] = parent
        keys["H"], keys["V"] = offset
    cmd(keys)


def delete(image_id, free=True):
    """Delete every placement of an image; free=True also drops its pixel data."""
    cmd({"a": "d", "d": "I" if free else "i", "i": image_id})


# --- animation (new in Ghostty 1.4) ----------------------------------------


def add_frame(image_id, rgba, w, h, gap_ms=None, x=0, y=0, base=None, replace=False):
    """Append a frame. With x/y/w/h smaller than the canvas it is a partial frame.

    base=N starts the new frame's canvas from frame N (1 = root), so a frame
    only needs to carry the pixels that changed. replace=True overwrites
    instead of alpha-blending (X=1).
    """
    keys = {"a": "f", "i": image_id, "f": 32, "s": w, "v": h}
    if x or y:
        keys["x"], keys["y"] = x, y
    if base:
        keys["c"] = base
    if replace:
        keys["X"] = 1
    if gap_ms:
        keys["z"] = gap_ms
    cmd(keys, rgba)


def set_gap(image_id, frame, gap_ms):
    """Set one frame's gap. The root frame (1) has none until you set it."""
    cmd({"a": "a", "i": image_id, "r": frame, "z": gap_ms})


def play(image_id, loops=None):
    """Start the terminal's own playback (s=3). loops=None loops forever."""
    cmd({"a": "a", "i": image_id, "s": 3, "v": 1 if loops is None else loops + 1})


def stop(image_id):
    cmd({"a": "a", "i": image_id, "s": 1})


def show_frame(image_id, frame):
    """Jump to a frame (c=N). With playback stopped, this is a cheap way to
    show one of a set of pre-rendered states: one tiny escape, no pixels."""
    cmd({"a": "a", "i": image_id, "c": frame})


# --- tiny raster helpers ----------------------------------------------------


def hex_rgb(s):
    s = s.lstrip("#")
    return tuple(int(s[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def render(w, h, shade):
    """Build RGBA bytes from shade(x, y) -> (r, g, b, a) with components 0..1."""
    out = bytearray(w * h * 4)
    i = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = shade(x, y)
            out[i] = int(max(0, min(1, r)) * 255)
            out[i + 1] = int(max(0, min(1, g)) * 255)
            out[i + 2] = int(max(0, min(1, b)) * 255)
            out[i + 3] = int(max(0, min(1, a)) * 255)
            i += 4
    return bytes(out)


def require_kitty_graphics():
    if os.environ.get("TMUX"):
        sys.exit("Run this outside tmux: tmux does not pass Kitty graphics through by default.")
    if not sys.stdout.isatty():
        sys.exit("stdout is not a terminal: run this directly in a Ghostty window.")
    if "ghostty" not in os.environ.get("TERM", "") and "kitty" not in os.environ.get("TERM", ""):
        print("note: TERM doesn't look like Ghostty or kitty; images may not show.", file=sys.stderr)


# Rose Pine: the palette the terminal and Claude Code themes already use here.
ROSE_PINE = {
    "base": hex_rgb("#191724"),
    "surface": hex_rgb("#1f1d2e"),
    "overlay": hex_rgb("#26233a"),
    "muted": hex_rgb("#6e6a86"),
    "text": hex_rgb("#e0def4"),
    "love": hex_rgb("#eb6f92"),
    "gold": hex_rgb("#f6c177"),
    "rose": hex_rgb("#ebbcba"),
    "pine": hex_rgb("#31748f"),
    "foam": hex_rgb("#9ccfd8"),
    "iris": hex_rgb("#c4a7e7"),
}


def rgb01(c):
    return tuple(v / 255 for v in c)


TAU = 2 * math.pi

---
source: https://ghostty.org/docs/config/keybind
fetched: 2025-11-09
title: Keybindings
---

# Keybindings

## Basic Syntax

The fundamental keybinding structure is:
```
keybind = trigger=action
```

## Trigger Configuration

### Key Specification
A trigger combines zero or more modifiers with one key. Valid examples include `a`, `ctrl+a`, `ctrl+shift+a`, and `ctrl+alt+a`.

The available keys derive from Chromium's keycodes and USB HID codes. For keys not in the standard list, you can specify Unicode codepoints directly—particularly useful for non-US keyboard layouts:

```
keybind = ctrl+ö=action
```

### Supported Modifiers
- `shift`
- `ctrl` (alias: `control`)
- `alt` (alias: `opt`, `option`)
- `super` (alias: `cmd`, `command`)

**Note:** Function and globe keys cannot be used as modifiers due to OS and GUI toolkit limitations.

## Trigger Prefixes

Multiple prefixes can combine. For example: `global:unconsumed:ctrl+a=reload_config`

| Prefix | Purpose |
|--------|---------|
| `all:` | Apply keybind to all terminal surfaces, not just focused one |
| `global:` | Works system-wide (macOS only; requires accessibility permissions) |
| `unconsumed:` | Don't consume input; send encoded value to running program |
| `performable:` | Only consume input if action can execute (e.g., copy when text selected) |

## Common Actions

| Action | Function |
|--------|----------|
| `ignore` | Ignore the keypress with no effect |
| `unbind` | Remove binding; pass key to child command if printable |
| `text:text` | Send string using Zig literal syntax (e.g., `text:\x15` sends Ctrl-U) |
| `csi:text` | Send CSI sequence (e.g., `csi:A` sends cursor up) |
| `esc:text` | Send escape sequence (e.g., `esc:d` deletes to end of word) |

For dozens of additional actions, consult the full Action Reference documentation.

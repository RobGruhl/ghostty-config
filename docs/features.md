---
source: https://ghostty.org/docs/features
fetched: 2025-11-09
title: Ghostty Features
---

# Ghostty Features

## Core Capabilities

Ghostty divides its feature set into two categories: **end-user features** and **developer features**.

### End-User Features
"Multi-window, tabs, splits, ligatures, auto-update" and similar capabilities enhance terminal usage without requiring changes to running applications like shells or editors.

### Developer Features
"Kitty graphics protocol, Kitty keyboard protocol, synchronized rendering, light/dark mode notifications" enable terminal applications to exceed capabilities in other emulators.

## Feature Highlights

**Cross-platform**: Runs on macOS and Linux with native UI components; Windows support is planned.

**GPU-accelerated rendering**: Uses Metal (macOS) and OpenGL (Linux) for terminal screen rendering.

**Themes**: "Hundreds of themes" selectable via single configuration line, with automatic switching based on system dark/light mode preference.

**Ligatures & Typography**: Proper rendering of ligature fonts with customizable font features.

**Grapheme clustering**: Correct rendering of multi-codepoint emoji and right-to-left scripts like Arabic and Hebrew.

**Kitty graphics protocol**: Enables terminal applications to render images directly.

## macOS-Specific Features

- Quick Terminal (menu bar animation)
- Native tabs and splits
- Proxy icon drag functionality
- Quick Look support
- Secure keyboard entry with visual lock indicator

## Terminal (VT) Compatibility

Ghostty prioritizes xterm compatibility, protocol origin compatibility, and de facto standard compatibility to support both legacy and modern terminal applications.

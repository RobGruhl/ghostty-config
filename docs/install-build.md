---
source: https://ghostty.org/docs/install/build
fetched: 2025-11-09
title: Build Ghostty from Source
---

# Build Ghostty from Source

## Overview

Building Ghostty from source is **not recommended for most users**. The documentation states: "If you have access to a prebuilt binary or package, you should use that instead."

## Core Requirements

### Zig Compiler (Version-Specific)

Each Ghostty version requires a specific Zig compiler version:

- Ghostty 1.0.x & 1.1.x → Zig 0.13.0
- Ghostty 1.2.x → Zig 0.14.1
- Development ("tip") → Zig 0.15.1

**Important note:** Older or newer Zig versions may fail to compile Ghostty.

## Source Code Acquisition

Download the official source tarball from:
```
https://release.files.ghostty.org/VERSION/ghostty-VERSION.tar.gz
```

Decompress and navigate:
```bash
tar -xf ghostty-VERSION.tar.gz
cd ghostty-VERSION/
```

## Build Command

```bash
zig build -Doptimize=ReleaseFast
```

Output locations:
- **Linux:** `zig-out/bin/ghostty`
- **macOS:** `zig-out/Ghostty.app`

## Linux Dependencies

**Required packages:**
- gtk4, libadwaita, gtk4-layer-shell, pkg-config, gettext

**Example (Arch Linux):**
```bash
sudo pacman -S gtk4 gtk4-layer-shell libadwaita gettext
```

**Installation (user-level):**
```bash
zig build -p $HOME/.local -Doptimize=ReleaseFast
```

**Installation (system-wide):**
```bash
zig build -p /usr -Doptimize=ReleaseFast
```

## macOS Requirements

- Xcode with active developer directory configured
- macOS and iOS SDKs installed
- Homebrew dependency: `brew install gettext`

## Alternative: Nix Build

```bash
nix build .#ghostty
```

Binary location: `./result/bin/ghostty`

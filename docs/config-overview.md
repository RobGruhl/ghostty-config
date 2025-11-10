---
source: https://ghostty.org/docs/config
fetched: 2025-11-09
title: Configuration Overview
---

# Configuration Overview

## Core Philosophy

Ghostty embraces a "zero configuration" approach, designed to function effectively without customization. The terminal includes sensible defaults, an embedded JetBrains Mono font, built-in nerd fonts support, and reasonable behaviors out-of-the-box. The developers actively work to eliminate unnecessary configuration requirements.

## Configuration Format

Ghostty uses a text-based configuration system with a straightforward `key = value` syntax. Future versions may include native graphical configuration tools alongside this text-based approach.

### File Locations

Configuration files are searched in this order, with later files overriding earlier ones:

**XDG Standard (all platforms):**
- `$XDG_CONFIG_HOME/ghostty/config`
- Falls back to `$HOME/.config/ghostty/config` if XDG_CONFIG_HOME is undefined

**macOS Specific:**
- `$HOME/Library/Application Support/com.mitchellh.ghostty/config`
- Also respects XDG paths

Configuration is completely optional; Ghostty runs fine without any custom config file.

### Syntax Rules

```ini
# Basic key-value pairs (whitespace around = is flexible)
background = 282c34
foreground = ffffff

# Comments use # and must occupy their own line
# Blank lines are permitted

# Multiple values supported
keybind = ctrl+z=close_surface
keybind = ctrl+d=new_split:right

# Empty values reset to defaults
font-family =
```

**Key Points:**
- Keys are case-sensitive (use lowercase)
- Values accept quoted or unquoted strings
- All config keys work as CLI flags: `ghostty --background=282c34`

### Modular Configuration

Split configuration across multiple files using the `config-file` directive:

```ini
config-file = some/relative/sub/config
config-file = ?optional/config
config-file = /absolute/path/config
```

- Relative paths are resolved relative to the current config file's location
- Prefix with `?` to make files optional (ignored if missing)
- `config-file` directives process at file end, preventing override of included settings

## Runtime Reloading

Press `ctrl+shift+,` (Linux) or `cmd+shift+,` (macOS) to reload configuration without restarting. Not all options support live reloading; some only affect newly created terminals.

## Documentation Resources

- Online reference at `/docs/config/reference`
- HTML/Markdown docs in `$prefix/share/ghostty/docs`
- Man pages in `$prefix/share/man`
- CLI: `ghostty +show-config --default --docs`
- Source code Config structure in GitHub repository

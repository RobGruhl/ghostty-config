# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the ghostty-config repository.

## Project Overview

This repository contains documentation and configuration examples for [Ghostty terminal emulator](https://ghostty.org/), a fast, native, GPU-accelerated terminal emulator for macOS and Linux.

**Repository Structure**:
```
ghostty-config/
├── docs/                      # Complete Ghostty documentation
│   ├── config-reference.md    # All configuration options
│   ├── features.md            # Feature overview
│   ├── keybindings.md         # Keyboard shortcuts
│   ├── shell-integration.md   # Shell integration setup
│   ├── integration-ccstatusline.md  # ccstatusline integration guide
│   └── ...
└── CLAUDE.md                  # This file
```

## Ghostty Overview

### Key Features

**Performance**:
- Written in Zig for native speed and low memory usage
- GPU-accelerated rendering (Metal on macOS, OpenGL on Linux)
- Faster than Electron-based terminals (WezTerm, Hyper)
- Lower latency than most terminal emulators

**Platform Integration**:
- Native macOS Swift/Zig implementation
- Proper Core Text font rendering (better than FreeType)
- Native window management and fullscreen
- System appearance detection (light/dark mode)

**Modern Terminal Features**:
- True color (24-bit) support
- 500+ built-in themes from iTerm2-Color-Schemes
- Automatic light/dark theme switching
- Kitty graphics protocol
- OSC 8 hyperlinks
- Shell integration (bash, zsh, fish, elvish)
- Split panes and tabs

**macOS-Specific Features**:
- Quick terminal (global hotkey dropdown)
- Native scrollbars and window chrome
- Proper Option key as Meta/Alt handling
- Window state persistence
- ProMotion display optimization (120Hz)

## Documentation Files

### Core Documentation

**[config-reference.md](docs/config-reference.md)**:
Complete reference for all Ghostty configuration options, organized by category:
- Font configuration (font-family, font-size, font-features)
- Colors and appearance (background, foreground, palette, themes)
- Window and display (padding, decorations, opacity)
- Input and mouse behavior
- Keybindings and shortcuts
- Shell integration
- Advanced features (quick terminal, clipboard, image protocol)

**[features.md](docs/features.md)**:
High-level overview of Ghostty's capabilities and design philosophy.

**[keybindings.md](docs/keybindings.md)**:
Default keyboard shortcuts and custom keybind configuration.

**[shell-integration.md](docs/shell-integration.md)**:
Setting up shell integration for enhanced features (semantic copy, prompt jumping, etc.).

### Integration Documentation

**[integration-ccstatusline.md](docs/integration-ccstatusline.md)**:
Detailed guide for integrating [ccstatusline](https://github.com/yourusername/ccstatusline) status line formatter with Ghostty, including:
- Automatic color alignment with Gruvbox themes
- macOS appearance-based theme switching
- Exact color palette matching
- Troubleshooting common issues

See also: Related project [ccstatusline](https://github.com/yourusername/ccstatusline) - Claude Code status line formatter with Ghostty integration

## Ghostty Configuration System

### Configuration File Location

**Default**: `~/.config/ghostty/config`

**Format**: Simple key-value pairs (not TOML, not INI)
```conf
# This is a comment
font-family = "JetBrains Mono"
font-size = 15.5
theme = dark:Gruvbox Dark,light:Gruvbox Light
```

### Key Configuration Concepts

**1. Themes**

Ghostty includes 500+ themes from the iTerm2-Color-Schemes repository:

```conf
# Single theme
theme = Gruvbox Dark

# Dual theme (auto-switching)
theme = dark:Gruvbox Dark,light:Gruvbox Light

# Custom theme file
theme = /path/to/custom.theme

# List available themes
$ ghostty +list-themes
```

**Theme Format** (iTerm2-Color-Schemes compatible):
```conf
background = #282828
foreground = #ebdbb2
cursor-color = #ebdbb2
palette = 0=#282828
palette = 1=#cc241d
# ... palette 0-255
```

**2. Color System**

Ghostty supports three color specification methods:

a) **Named colors** (X11 color names):
```conf
background = white
foreground = black
```

b) **Hex colors**:
```conf
background = #282828
foreground = #EBDBB2
```

c) **256-color palette**:
```conf
palette = 0=#282828
palette = 1=#cc241d
# ... up to 255
```

All palette indices support decimal, binary (`0b`), octal (`0o`), and hex (`0x`) notation.

**3. Font Configuration**

Ghostty uses native font rendering (Core Text on macOS):

```conf
# Font family with fallbacks
font-family = "JetBrains Mono"
font-family = "SF Mono,Monaco,Menlo"

# Font size (points, supports decimals)
font-size = 15.5

# Font features (OpenType)
font-feature = +ss01  # Enable stylistic set 1
font-feature = -calt  # Disable ligatures

# List available fonts
$ ghostty +list-fonts
```

**4. Keybindings**

Custom keybinds use W3C key codes and modifiers:

```conf
# Format: modifier+key=action
keybind = cmd+k=clear_screen
keybind = ctrl+a>n=new_window  # Sequence: Ctrl+A then N

# Global keybinds (work outside Ghostty)
keybind = global:super+`=toggle_quick_terminal

# Clear all defaults and start fresh
keybind = clear
```

**5. Quick Terminal (macOS)**

Dropdown terminal accessible system-wide:

```conf
keybind = global:super+`=toggle_quick_terminal
quick-terminal-position = left
quick-terminal-size = 50%
quick-terminal-autohide = true
```

## Color Palette Details

### Gruvbox Dark (Official iTerm2-Color-Schemes)

The most popular retro groove color scheme:

```conf
background = #282828
foreground = #ebdbb2
cursor-color = #ebdbb2

# Standard ANSI colors (0-7)
palette = 0=#282828   # Black
palette = 1=#cc241d   # Red
palette = 2=#98971a   # Green
palette = 3=#d79921   # Yellow
palette = 4=#458588   # Blue
palette = 5=#b16286   # Magenta
palette = 6=#689d6a   # Cyan
palette = 7=#a89984   # White

# Bright ANSI colors (8-15)
palette = 8=#928374   # Bright Black
palette = 9=#fb4934   # Bright Red
palette = 10=#b8bb26  # Bright Green
palette = 11=#fabd2f  # Bright Yellow
palette = 12=#83a598  # Bright Blue
palette = 13=#d3869b  # Bright Magenta
palette = 14=#8ec07c  # Bright Cyan
palette = 15=#ebdbb2  # Bright White
```

**Design Philosophy**:
- Warm, muted color palette
- Comfortable for long coding sessions
- High readability with good contrast (WCAG compliant)
- Originally designed for Vim by [@morhetz](https://github.com/morhetz/gruvbox)

### Gruvbox Light

Inverted palette optimized for light backgrounds:

```conf
background = #fbf1c7
foreground = #3c3836
cursor-color = #3c3836

# Adjusted palette for light mode
palette = 0=#fbf1c7
palette = 1=#cc241d
palette = 2=#98971a
# ... (see integration-ccstatusline.md for complete palette)
```

### Color Source Attribution

All Ghostty themes are sourced from [mbadolato/iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes), a community-maintained repository providing standardized terminal color schemes across 100+ terminal emulators.

## Related Projects

### ccstatusline Integration

[ccstatusline](https://github.com/yourusername/ccstatusline) is a Claude Code status line formatter with special Ghostty integration:

**Features**:
- Gruvbox themes using exact Ghostty color palette
- Automatic macOS appearance detection
- Theme switching synchronized with Ghostty's dual-theme system
- Powerline-style rendering with customizable widgets

**Setup**:
1. Install: `npm install -g ccstatusline`
2. Configure: `ccstatusline` (TUI mode)
3. Enable in Claude Code: `~/.claude/settings.json` → `statusLine.command = "ccstatusline"`
4. See [integration-ccstatusline.md](docs/integration-ccstatusline.md) for details

## Development Notes

When working with this documentation:

**Adding New Documentation**:
- Place all docs in `docs/` directory
- Use Markdown format with YAML frontmatter
- Include source URLs where applicable
- Cross-reference related topics
- Maintain consistent formatting and structure

**Updating Configuration Examples**:
- Verify configuration options against official Ghostty documentation
- Test examples before documenting
- Note version requirements for newer features
- Include both simple and advanced examples

**Color Scheme Documentation**:
- Always attribute color schemes to original authors
- Link to source repositories (iTerm2-Color-Schemes, original theme repos)
- Provide both hex and ANSI 256 values when possible
- Note WCAG contrast compliance where relevant

## Useful Commands

```bash
# List available themes
ghostty +list-themes

# List available fonts
ghostty +list-fonts

# Get help
ghostty +help

# Launch with specific config
ghostty --config=/path/to/config

# Launch quick terminal
ghostty --quick-terminal
```

## Resources

**Official**:
- Website: https://ghostty.org/
- Documentation: https://ghostty.org/docs
- GitHub: https://github.com/ghostty-org/ghostty

**Community**:
- iTerm2-Color-Schemes: https://github.com/mbadolato/iTerm2-Color-Schemes
- Gruvbox: https://github.com/morhetz/gruvbox

**Related Tools**:
- ccstatusline: https://github.com/yourusername/ccstatusline
- Claude Code: https://claude.com/code

## Important Notes

- Ghostty is actively developed; features may change between versions
- This documentation focuses on version 1.0.0+
- Always check official docs for the latest configuration options
- Configuration syntax is unique to Ghostty (not TOML or standard INI format)
- Theme names are case-sensitive (e.g., "Gruvbox Dark" not "gruvbox dark")
- Automatic theme switching requires macOS 10.14+ (Mojave) for appearance detection

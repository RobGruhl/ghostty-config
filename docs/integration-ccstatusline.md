---
title: ccstatusline Integration with Ghostty
author: Claude Code Documentation
date: 2025-11-11
---

# ccstatusline Integration with Ghostty

This guide explains how to use [ccstatusline](https://github.com/yourusername/ccstatusline) with Ghostty terminal for a seamless, color-coordinated Claude Code experience.

## Overview

ccstatusline is a customizable status line formatter for Claude Code CLI that provides:
- Real-time display of model info, git status, and token usage
- Powerline-style rendering with customizable themes
- **Automatic color alignment with Ghostty themes**
- **macOS appearance detection for auto-switching themes**

## Prerequisites

- Ghostty terminal emulator ([installation guide](install-build.md))
- Claude Code CLI
- Node.js 14+ or Bun runtime

## Installation

### Option 1: NPM (Recommended)
```bash
npm install -g ccstatusline
```

### Option 2: Bunx (No Installation)
```bash
# No installation needed - runs on-demand
bunx ccstatusline
```

### Option 3: Build from Source
```bash
git clone https://github.com/yourusername/ccstatusline.git
cd ccstatusline
bun install
bun run build
npm link
```

## Configuration

### 1. Enable in Claude Code

Add ccstatusline to your Claude Code settings:

**Location**: `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`)

```json
{
  "statusLine": {
    "enabled": true,
    "command": "ccstatusline"
  }
}
```

### 2. Configure Ghostty Theme

In your Ghostty config (`~/.config/ghostty/config`):

```conf
# Option A: Gruvbox with automatic light/dark switching (Recommended)
theme = dark:Gruvbox Dark,light:Gruvbox Light

# Option B: Gruvbox Dark only
theme = Gruvbox Dark

# Option C: Gruvbox Light only
theme = Gruvbox Light
```

### 3. Configure ccstatusline Theme

Run the interactive configuration:

```bash
ccstatusline
```

Navigate to **Powerline Setup** and select:
- **Theme**: `gruvbox` (for automatic switching) or `gruvbox-light`
- **Enable Powerline**: Yes
- **Separators**: Use Powerline arrows (requires Powerline fonts)

## Color Alignment Details

### How It Works

ccstatusline's Gruvbox themes use **exact color values** from Ghostty's official Gruvbox themes, sourced from the [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) repository.

**Gruvbox Dark Palette**:
```
Background:  #282828   Foreground:  #EBDBB2
Red:         #CC241D   Bright Red:  #FB4934
Green:       #98971A   Bright Green: #B8BB26
Yellow:      #D79921   Bright Yellow: #FABD2F
Blue:        #458588   Bright Blue:  #83A598
Magenta:     #B16286   Bright Magenta: #D3869B
Cyan:        #689D6A   Bright Cyan:  #8EC07C
Gray:        #A89984   Bright Gray:  #928374
```

**Gruvbox Light Palette**:
```
Background:  #FBF1C7   Foreground:  #3C3836
(Inverted and optimized for light backgrounds)
```

### Automatic Theme Switching

When you select the `gruvbox` powerline theme in ccstatusline, it automatically detects macOS system appearance and switches between:

- **Dark Mode** → `gruvbox` theme (matches Ghostty's Gruvbox Dark)
- **Light Mode** → `gruvbox-light` theme (matches Ghostty's Gruvbox Light)

This mirrors Ghostty's dual-theme behavior, ensuring perfect visual consistency.

**Technical Implementation**:
1. ccstatusline reads `defaults read -g AppleInterfaceStyle` on each render
2. Resolves theme name based on current appearance
3. Applies matching color palette from the same iTerm2-Color-Schemes source

### Color Level Support

ccstatusline provides three color rendering levels:

| Level | Name | Description | Use Case |
|-------|------|-------------|----------|
| 1 | ansi16 | 16 basic ANSI colors | Legacy terminals |
| 2 | ansi256 | 256-color palette | Standard modern terminals |
| 3 | truecolor | 24-bit RGB colors | Ghostty, iTerm2, modern terminals |

Ghostty supports **truecolor** (level 3), providing the highest fidelity color matching.

## Visual Examples

### Dark Mode
```
┌─ Ghostty Terminal (Gruvbox Dark) ─────────────────────┐
│ Background: #282828                                    │
│ ┌────────────────────────────────────────────────┐   │
│ │  Model  Git Branch  Token Usage  Context      │   │
│ │  Sonnet 4.5  main  15.2K  32%               │   │
│ └────────────────────────────────────────────────┘   │
│   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   │
│   ccstatusline with matching Gruvbox Dark colors      │
└────────────────────────────────────────────────────────┘
```

### Light Mode
```
┌─ Ghostty Terminal (Gruvbox Light) ────────────────────┐
│ Background: #FBF1C7                                    │
│ ┌────────────────────────────────────────────────┐   │
│ │  Model  Git Branch  Token Usage  Context      │   │
│ │  Sonnet 4.5  main  15.2K  32%               │   │
│ └────────────────────────────────────────────────┘   │
│   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   │
│   ccstatusline with matching Gruvbox Light colors     │
└────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Colors Don't Match

**Problem**: ccstatusline colors look different from Ghostty theme

**Solutions**:
1. Verify Ghostty is using Gruvbox theme: `ghostty +list-themes | grep Gruvbox`
2. Check ccstatusline color level: In TUI, go to **Global Overrides** → **Color Level** → Select "truecolor (level 3)"
3. Ensure Ghostty config uses exact theme name: `Gruvbox Dark` (case-sensitive)

### Theme Not Auto-Switching

**Problem**: ccstatusline doesn't switch between light/dark

**Solutions**:
1. Verify you're on macOS (auto-switching only works on macOS)
2. Check ccstatusline theme is set to `gruvbox` (not `gruvbox-light`)
3. Test appearance detection: `defaults read -g AppleInterfaceStyle` (should return "Dark" or error for light)
4. Restart Claude Code session after changing macOS appearance

### Powerline Arrows Not Showing

**Problem**: Seeing boxes or question marks instead of arrows

**Solutions**:
1. Install Powerline fonts: `brew tap homebrew/cask-fonts && brew install --cask font-jetbrains-mono-nerd-font`
2. In Ghostty config, set: `font-family = "JetBrainsMono Nerd Font"`
3. Or use ccstatusline's built-in installer: In TUI → **Powerline Setup** → **Install Powerline Fonts**

## Advanced Configuration

### Custom Color Overrides

While the Gruvbox themes provide automatic alignment, you can override specific widget colors:

```bash
# Run TUI
ccstatusline

# Navigate: Main Menu → Color Customization
# Select widget and choose custom hex color
```

Note: Custom colors will override automatic theme matching for that widget.

### Multiple Status Lines

You can configure multiple status lines with different themes:

```bash
# Line 1: Gruvbox auto-switching powerline
# Line 2: Custom colors or different theme
```

Each line can have independent powerline configuration and colors.

## Related Documentation

- [Ghostty Configuration Reference](config-reference.md) - Complete Ghostty configuration options
- [Ghostty Themes](features.md#themes) - Built-in theme system
- [ccstatusline README](https://github.com/yourusername/ccstatusline) - Full feature documentation
- [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) - Source of color definitions

## Color Scheme Philosophy

Both Ghostty and ccstatusline follow a philosophy of:

1. **Standardization**: Using widely-adopted color schemes (iTerm2-Color-Schemes)
2. **Consistency**: Exact color matching across tools
3. **Accessibility**: WCAG-compliant contrast ratios
4. **Automation**: Intelligent theme switching without manual configuration

This integration embodies these principles, providing a seamless visual experience from terminal to status line.

## Feedback and Support

- Report ccstatusline issues: [GitHub Issues](https://github.com/yourusername/ccstatusline/issues)
- Report Ghostty issues: [ghostty.org](https://ghostty.org/)
- Suggest integration improvements: Open an issue in either repository

---

**Last Updated**: 2025-11-11
**ccstatusline Version**: ≥1.0.0
**Ghostty Version**: ≥1.0.0

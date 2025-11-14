---
source: https://ghostty.org/docs/config/reference
fetched: 2025-11-09
title: Configuration Option Reference
---

# Configuration Option Reference

This comprehensive guide documents all Ghostty terminal emulator configuration options, organized by category.

## Font Configuration

**font-family, font-family-bold, font-family-italic, font-family-bold-italic**
Specifies font families with fallback support. Generate valid values via `ghostty +list-fonts`. Styles synthesize automatically if unavailable.

**font-style, font-style-bold, font-style-italic, font-style-bold-italic**
Named font styles matching font advertisements (e.g., "Heavy"). Set to `false` to disable specific styles.

**font-synthetic-style**
Controls synthesis of unavailable styles (bold, italic, bold-italic). Disable specific styles with comma-separated values like "no-bold,no-italic".

**font-feature**
Applies OpenType font features using syntax like `+feat`, `-feat`, or `feat=value`. Supports disabling ligatures with `-calt`.

**font-size**
Size in points (supports decimals). Non-integer values calculate nearest pixel size on high-DPI displays.

**font-variation, font-variation-bold, font-variation-italic, font-variation-bold-italic**
Sets axes for variable fonts using format `id=value` (e.g., `wght=600`).

**font-codepoint-map**
Forces Unicode codepoint ranges to specific fonts using syntax `U+ABCD-U+DEFG=fontname`.

**font-thicken, font-thicken-strength**
macOS-only: thickens font strokes with strength values 0-255.

**font-shaping-break**
Locations to break font shaping runs. Supports `cursor` option to break runs under the cursor (Available since: 1.2.0).

## Color and Appearance

**alpha-blending**
Color space for alpha blending: `native`, `linear`, or `linear-corrected` (Available since: 1.1.0).

**background, foreground**
Window colors as hex (#RRGGBB) or X11 names.

**background-image, background-image-opacity, background-image-position, background-image-fit, background-image-repeat**
Background image configuration (Available since: 1.2.0). Supports PNG/JPEG with opacity, position, fit modes (contain/cover/stretch/none), and repeat options.

**selection-foreground, selection-background**
Selection colors or special values: `cell-foreground`, `cell-background` (Available since: 1.2.0).

**selection-clear-on-typing, selection-clear-on-copy**
Control selection clearing behavior (Available since: 1.2.0).

**minimum-contrast**
WCAG 2.0 contrast ratio (1-21) to ensure readable text.

**palette**
256-color terminal palette using `N=COLOR` format with decimal/binary/octal/hex indices.

**cursor-color, cursor-opacity, cursor-text**
Cursor styling with special values for matching cell colors (Available since: 1.2.0).

**cursor-style**
Options: `block`, `bar`, `underline`, `block_hollow`.

**cursor-style-blink**
Default cursor blinking state; respects DEC Mode 12 when unset.

## Cell and Layout Adjustments

**adjust-cell-width, adjust-cell-height**
Integer or percentage adjustments to cell dimensions.

**adjust-font-baseline**
Distance adjustment from cell bottom to text baseline (pixels or percentage).

**adjust-underline-position, adjust-underline-thickness**
Position and thickness for underlines (pixels or percentage).

**adjust-strikethrough-position, adjust-strikethrough-thickness**
Position and thickness for strikethroughs (pixels or percentage).

**adjust-overline-position, adjust-overline-thickness**
Position and thickness for overlines (pixels or percentage).

**adjust-cursor-thickness, adjust-cursor-height**
Cursor size adjustments for bar/rect styles (pixels or percentage).

**adjust-box-thickness**
Box drawing character thickness (pixels or percentage).

**adjust-icon-height**
Nerd font icon maximum height (pixels or percentage). Default is 1.2× capital letter height (Available since: 1.2.0).

**grapheme-width-method**
Width calculation: `legacy` (wcswidth compatibility) or `unicode` standard. Mode 2027 forces unicode.

## FreeType and Platform-Specific

**freetype-load-flags**
FreeType rendering options (Linux only): `hinting`, `force-autohint`, `monochrome`, `autohint`.

**theme**
Built-in, custom, or absolute path themes. Supports light/dark modes: `light:theme,dark:theme`.

> **Note**: For Claude Code users, the [ccstatusline](https://github.com/yourusername/ccstatusline) status line formatter has Gruvbox themes that automatically align with Ghostty's Gruvbox Dark/Light palettes and support automatic theme switching based on macOS appearance. See [integration-ccstatusline.md](integration-ccstatusline.md) for details.

## Window and Display

**window-padding-x, window-padding-y**
Padding between cells and window borders (points). Format: single value or `left,right` / `top,bottom`.

**window-padding-balance**
Auto-balance padding across edges when dimensions don't align perfectly.

**window-padding-color**
Padding area color: `background`, `extend`, or `extend-always`.

**window-vsync**
Synchronize rendering with screen refresh (macOS only).

**window-inherit-working-directory, window-inherit-font-size**
Inherit settings from previous terminal.

**window-decoration**
Window style: `none`, `auto`, `client`, `server` (Available since: 1.1.0 for client/server).

**window-title-font-family**
Custom font for window and tab titles (GTK, Available since: 1.1.0).

**window-subtitle**
Display working directory in subtitle (GTK, Available since: 1.1.0).

**window-theme**
Theme source: `auto`, `system`, `light`, `dark`, `ghostty` (GTK only).

**window-colorspace**
Color interpretation: `srgb` or `display-p3` (macOS only).

**window-height, window-width**
Initial window size in grid cells (both required).

**window-position-x, window-position-y**
Starting position in pixels from top-left (macOS only).

**window-save-state**
State persistence: `default`, `never`, `always` (macOS only).

**window-step-resize**
Resize in cell increments rather than pixels (macOS only).

**window-new-tab-position**
New tabs inserted at `current` or `end`.

**window-show-tab-bar**
Tab bar visibility: `always`, `auto`, `never` (GTK, Available since: 1.2.0).

**window-titlebar-background, window-titlebar-foreground**
Custom titlebar colors (GTK with `window-theme=ghostty`).

## Resizing and Overlays

**resize-overlay**
When to show resize feedback: `always`, `never`, `after-first`.

**resize-overlay-position**
Overlay location: center, corners, or edges.

**resize-overlay-duration**
Overlay display time with flexible duration syntax (y/d/h/m/s/ms/us/ns units).

## Mouse and Input

**cursor-click-to-move**
Alt+click (Linux) or Option+click (macOS) to move cursor at prompts (requires shell integration).

**mouse-hide-while-typing**
Automatically hide mouse cursor while typing.

**scroll-to-bottom**
Scroll triggers: `keystroke`, `output` (output currently unimplemented).

**mouse-shift-capture**
Shift+click behavior: `true`, `false`, `always`, `never`.

**mouse-scroll-multiplier**
Mouse wheel scroll distance (0.01-10000, default 3 lines) (Available since: 1.2.0).

**copy-on-select**
Auto-copy selection to clipboard. Value `clipboard` copies to both clipboards.

**right-click-action**
Right-click behavior: `context-menu`, `paste`, `copy`, `copy-or-paste`, `ignore`.

**click-repeat-interval**
Milliseconds between clicks for multi-click detection.

## Background and Opacity

**background-opacity**
Window background opacity (0-1). Disabled in fullscreen on macOS.

**background-opacity-cells**
Apply opacity to cells with explicit background colors (Available since: 1.2.0).

**background-blur**
Blur intensity when opacity <1. Boolean or integer value. Supported on macOS and some Linux environments (KDE Plasma).

**unfocused-split-opacity**
Opacity of unfocused split panes (0.15-1).

**unfocused-split-fill**
Dimming color for unfocused splits (defaults to background).

**split-divider-color**
Split divider color (Available since: 1.1.0).

## Command and Environment

**command**
Shell or command to execute. Use `direct:` prefix to avoid shell expansion (Available since: 1.2.0) or `shell:` to force wrapping.

**initial-command**
First-surface-only command. Supports `-e` CLI flag with auto-configuration adjustments.

**env**
Environment variables as `KEY=VALUE` pairs. Empty value resets map; empty key removes specific variable (Available since: 1.2.0).

**input**
Data to send on startup using `raw:string` or `path:filepath` formats. Repeatable (Available since: 1.2.0).

**wait-after-command**
Keep terminal open after command exit pending keypress.

**abnormal-command-exit-runtime**
Milliseconds threshold for "too quick" exit detection.

## Scrollback and History

**scrollback-limit**
Scrollback buffer size in bytes (lazy allocation).

## Linking and URLs

**link**
Match regex patterns to actions. Earlier configs take precedence.

**link-url**
Enable URL matching and system opening (default enabled).

**link-previews**
Show previews for matched URLs, OSC 8 hyperlinks only, or never (Available since: 1.2.0).

## Behavior and Features

**maximize, fullscreen**
Window state on startup (maximize Available since: 1.1.0).

**title**
Force window title (use spaces for blank title).

**class**
Application class (WM_CLASS X11, Wayland app ID, DBus name). Default: `com.mitchellh.ghostty`.

**x11-instance-name**
X11 WM_CLASS instance name (default: `ghostty`).

**working-directory**
Initial directory: `home`, `inherit`, or absolute path.

**confirm-close-surface**
Confirmation before closing surface or always (`true`/`false`/`always`).

**quit-after-last-window-closed**
Exit application after last window closes (default: false on macOS, true on Linux).

**quit-after-last-window-closed-delay**
Delay before exit with duration syntax. Linux only (Available since: 1.2.0).

**initial-window**
Create initial window on startup (Linux/macOS only).

**undo-timeout**
Operation undo availability duration with flexible syntax (macOS only, Available since: 1.2.0).

## Quick Terminal (Dropdown Terminal)

**quick-terminal-position**
Position: `top`, `bottom`, `left`, `right`, `center`.

**quick-terminal-size**
Size as percentage (`20%`) or pixels (`300px`), supports comma-separated values.

**gtk-quick-terminal-layer**
Layer: `overlay`, `top`, `bottom`, `background` (GTK Wayland, Available since: 1.2.0).

**gtk-quick-terminal-namespace**
Window identifier for Wayland compositors (GTK Wayland, Available since: 1.2.0).

**quick-terminal-screen**
Target screen: `main`, `mouse`, `macos-menu-bar` (macOS only).

**quick-terminal-animation-duration**
Animation seconds (0 to disable).

**quick-terminal-autohide**
Auto-hide on focus loss (default: true on macOS, false on Linux).

**quick-terminal-space-behavior**
Space switching: `move` or `remain` (macOS, Available since: 1.1.0).

**quick-terminal-keyboard-interactivity**
Input handling: `none`, `on-demand`, `exclusive` (Linux Wayland, Available since: 1.2.0).

## Keybindings

**keybind**
Format: `trigger=action`. Triggers use `+`-separated modifiers (shift/ctrl/alt/super) and keys (physical W3C codes or Unicode codepoints). Sequences use `>`: `ctrl+a>n=new_window`. Special prefixes: `global:`, `all:`, `unconsumed:`, `performable:` (Available since: 1.0.0-1.1.0). Special values: `ignore`, `unbind`, `csi:`, `esc:`, `text:`, action names. Clear all with `keybind=clear`.

## Shell Integration and Terminal API

**shell-integration**
Auto-injection: `none`, `detect`, `bash`, `elvish`, `fish`, `zsh`.

**shell-integration-features**
Features list: `cursor`, `sudo`, `title`, `ssh-env`, `ssh-terminfo` (comma-separated, prefix with `no-` to disable, Available since: 1.2.0 for SSH features).

**title-report**
Enable title query via CSI 21 t (security risk, disabled by default, Available since: 1.0.1).

**image-storage-limit**
Image protocol memory per screen (0 disables, default 320MB, max 4GB).

## Clipboard

**clipboard-read, clipboard-write**
Permissions: `ask`, `allow`, `deny` (OSC 52).

**clipboard-trim-trailing-spaces**
Remove trailing whitespace from copied text.

**clipboard-paste-protection**
Require confirmation for pasted unsafe text.

**clipboard-paste-bracketed-safe**
Consider bracketed pastes safe (default true).

## Configuration

**config-file**
Load additional config files (repeatable, paths relative to current file). Prefix with `?` to suppress missing file errors.

**config-default-files**
Load default config paths. CLI-only option.

## Command Palette

**command-palette-entry**
Custom command palette entries with `title:`, `action:`, and optional `description:` fields. Clear defaults with empty value.

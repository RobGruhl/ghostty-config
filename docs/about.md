---
source: https://ghostty.org/docs/about
fetched: 2025-11-09
title: About Ghostty
---

# About Ghostty

Ghostty is positioned as a terminal emulator balancing three key attributes: speed, feature richness, and native UI design. The project is maintained by Mitchell Hashimoto as a passion project developed in his spare time.

## Native

The application is built natively for each platform:

- **macOS**: Swift-based GUI using AppKit and SwiftUI
- **Linux**: Zig-based GUI leveraging GTK4 C API

Both platforms share a common terminal emulation core called "libghostty" written in Zig. The implementation uses native UI components for tabs, splits, and dialogs rather than custom text-based widgets. Platform-specific integrations include Quick Look and secure input APIs on macOS.

## Feature-Rich

Two categories of capabilities are emphasized:

1. **Terminal features** enabling programs running inside Ghostty to access advanced protocols (Kitty graphics, hyperlinks, light/dark mode notifications)
2. **Application features** for user interaction with the emulator itself (native tabs, splits, dropdown terminal on macOS, theme switching)

## Fast

Performance claims are measured relative to competing emulators. Speed encompasses startup time, scrolling responsiveness, input/output throughput, and frame rates.

## libghostty Architecture

The C-ABI compatible library enables clean separation between terminal emulation and GUI implementation, potentially allowing third-party developers to build alternative interfaces on this shared foundation.

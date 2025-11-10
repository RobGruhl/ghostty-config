---
source: https://ghostty.org/docs/linux
fetched: 2025-11-09
title: Linux Platform Documentation
---

# Linux Platform Documentation

## Installation Options

Ghostty provides two primary installation methods for Linux users:

1. **Pre-built Packages** - "Pre-built packages for quick setup on most popular Linux distributions"
2. **Build from Source** - "Download a source tarball and build Ghostty from source"

Both approaches are documented in the installation guides.

## GTK/Adwaita Version Requirements

Ghostty maintains specific minimum dependency versions:

| Version | GTK | Adwaita |
|---------|-----|---------|
| 1.2.x | 4.14 | 1.5 |
| 1.1.x | 4.8 | 1.2 |

### Versioning Policy

The project bases minimum requirements on what's available in the latest LTS releases of Debian, Fedora, and Ubuntu. Patch releases (the Z in X.Y.Z) never increase dependencies, allowing safe updates within a minor version.

The documentation notes: "Backporting feature support to older GTK/Adwaita versions is impractical from a maintenance perspective."

## Platform Support

Ghostty works on both Wayland and X11 across various Linux distributions. The documentation acknowledges that "due to the diversity of Linux distributions, desktop environments, launchers, etc." some environments may require additional configuration notes.

## Additional Resources

- Systemd and D-Bus integration documentation is available
- Shell integration features are supported
- Color theme customization options exist

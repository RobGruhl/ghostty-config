---
source: https://ghostty.org/docs/features/shell-integration
fetched: 2025-11-09
title: Shell Integration
---

# Shell Integration

## Overview

Ghostty provides shell integration for bash, zsh, fish, and elvish that enables advanced terminal features through automatic code injection.

## Key Features

Shell integration unlocks several capabilities:

- **Smart terminal closing**: "Do not confirm close for terminals where the cursor is at a prompt"
- **Directory awareness**: New terminals inherit the working directory from the previously active terminal
- **Prompt handling**: Complex prompts render correctly through shell redraw rather than reflow
- **Command selection**: Control+click (or Cmd+click on macOS) selects command output
- **Text editing cursor**: The prompt displays a bar cursor for typical text editing
- **Prompt navigation**: The `jump_to_prompt` keybinding scrolls through prompts
- **Click positioning**: Alt+click (Option+click on macOS) positions the cursor at the click location
- **sudo/ssh wrapping**: Optional automatic wrapping to preserve terminfo compatibility

## Automatic Injection

Ghostty automatically injects integration code for supported shells. However, "The version of Bash distributed with macOS (`/bin/bash`) does not support automatic shell integration." You'll need to either manually source the script or install Bash from Homebrew.

Some shells like Nushell and Fish 4.0+ have built-in support for certain features, eliminating the need for explicit integration.

## Manual Setup

For manual configuration, source the appropriate script in your shell configuration file using the `GHOSTTY_RESOURCES_DIR` environment variable:

| Shell | Path |
|-------|------|
| bash | `${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash` |
| zsh | `${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration` |
| fish | `"$GHOSTTY_RESOURCES_DIR"/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish` |
| elvish | `${GHOSTTY_RESOURCES_DIR}/shell-integration/elvish/lib/ghostty-integration.elv` |

## Verification & Troubleshooting

Look for these log lines confirming successful injection:
- `info(io_exec): shell integration automatically injected shell=...`

If integration fails, "the main culprit is usually that `GHOSTTY_RESOURCES_DIR` is not pointing to the right place."

## Shell Switching Limitation

Automatic integration only applies to the initially launched shell. When switching shells within Ghostty, "the shell integration will be lost in that shell" unless manually sourced in the new shell's configuration.

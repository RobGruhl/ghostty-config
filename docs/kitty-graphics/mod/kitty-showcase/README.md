# kitty-showcase

A Claude Code pane drawn with the Kitty graphics protocol (Ghostty 1.4+, kitty). Run `/kitty-showcase` to open it. It shows an orb that follows the session (idle, thinking, running a tool, with the tool's name) and a ring gauge of the context window's fill. The orb's frames are rendered once per mode and swapped with `$.ui.blit`. The ring is redrawn when the fill changes. Other terminals and surfaces get a text fallback.

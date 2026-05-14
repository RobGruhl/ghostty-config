---
title: Experimental
chapter: 9
---

# Experimental

The bleeding edge — audio-reactivity, live-coding, prerelease features.
Higher chance of breakage or missing tooling. Pin a date in your bookmark
for these because the API surface here moves quickly.

## Audio-reactive shaders

Ghostty does *not* (yet) expose audio data directly to shaders —
`iSampleRate` is documented as **N/A**. Community experiments work around
this by piping audio into a texture or uniform externally:

- Run a background process that samples system audio (e.g. via `cpal`,
  `ffmpeg`, `parec`) and FFT's it.
- Write the FFT bins into a file or shared region.
- Either (a) write a small Ghostty shader fork patch that reads them as a
  uniform, or (b) drive a config-reload loop that updates a `.glsl` file
  with hardcoded values — janky but works without forking.

Discussion thread on r/Ghostty (live-coding audio-reactive shaders):
<https://www.reddit.com/r/Ghostty/comments/1o28x2j/livecoding_audioreactive_shaders_in_ghostty/>

This area is wide open. If you've got an Apple Silicon Mac, the easiest
hack is a `swift` helper using `AVAudioEngine` that writes mean-spectrum
amplitudes to a 1×16 texture — but you'd need a Ghostty patch to bind that
texture in place of `iChannel0` or as an additional channel. Not yet
upstream.

## Live-coding workflow

The recommended live-coding loop today, without audio:

1. Edit your `.glsl` in your editor.
2. Reload Ghostty with `Cmd+Shift+,` to pick up the new shader. (Config
   changes apply at runtime to all open terminals — verified in Config.zig:
   *"This can be changed at runtime and will affect all open terminals."*)
3. Tail the log if compilation fails — errors don't surface in the UI.

A tighter loop is possible via `entr` / `fswatch`:

```bash
echo ~/.config/ghostty/shaders/myshader.glsl | entr -p touch ~/.config/ghostty/config
```

This re-touches the config every time the shader changes, which on most
Ghostty builds triggers reload. Less surgical than Shadertoy.com's live
preview but it works against the *actual* render pipeline.

## Prerelease uniforms

Some uniforms in [chapter 3](03-uniforms-reference.md) — particularly the
cursor-tracking and `iFocus`/`iTimeFocus` set — are documented in the
`main` branch of Ghostty but landed in 1.x development builds rather than a
formal stable release. If you target stability, gate experimentation behind
a check:

```bash
ghostty --version
```

The minimum useful version for everything in this library is whatever your
package manager last pulled from `main` (or any 1.2.0+ build).

## Future areas

Watching: official audio support, mouse-input support (currently `iMouse`
is **NOT CURRENTLY SUPPORTED** per Config.zig), and any official animation
hooks for the cursor blink. The cursor uniforms today already enable smooth
animation in shader-land, so that may never get a dedicated event.

## Reporting bugs / contributing

- Ghostty repo: <https://github.com/ghostty-org/ghostty>
- Community shaders: <https://github.com/hackr-sh/ghostty-shaders>
  (PRs welcome — many contributors)

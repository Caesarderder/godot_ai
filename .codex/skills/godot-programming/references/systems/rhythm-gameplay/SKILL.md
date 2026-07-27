---
name: rhythm-gameplay
description: Use when implementing Godot 4.6 GDScript rhythm clocks, BPM maps, note charts, judgment windows, latency calibration, combo, scoring events, and note lifecycle for Web games
---

# Rhythm Gameplay for Godot 4.6 Web

Own the musical timeline and deterministic judgment. Reuse **audio-system** for buses and playback, **input-handling** for actions/devices, **game-balance** for windows and scoring, **animation-system** for presentation, and **save-load** for calibration persistence.

## Clock contract

Use the playing stream as the timeline authority:

`playback_position + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()`

Treat this as an estimate that must be measured on target browsers/devices. Keep visual interpolation separate from judgment time. A chart maps stable note IDs to beat/time using an explicit BPM/tempo map and offset.

## Note lifecycle

`scheduled -> spawned -> hittable -> judged(hit/miss) -> retired`

Judgment accepts an input once, chooses the closest eligible note under a deterministic tie-break, computes signed timing error, assigns a configured window, and emits a result. Presentation observes the result; it does not move the authoritative timestamp.

Calibration stores a bounded player offset with device/browser context as appropriate. Never claim one universal latency value. Define pause, seek, restart, dropped-frame, focus-loss, and audio-resume behavior before implementing combo or score.

## Web constraints

Browser audio may require a user gesture and can be suspended in the background. Handle audio-context resume and focus changes explicitly. Do not use thread workers, native low-latency plugins, or frame count as the judgment clock in the default path.

## Verification

Test BPM changes, chart ordering, boundary windows, simultaneous notes, repeated input, pause/resume, seek/restart, focus loss, calibration bounds, and deterministic score reconstruction. Automated timing tests need a fake clock; final acceptance requires real browser/device observation with recorded timing error distributions.

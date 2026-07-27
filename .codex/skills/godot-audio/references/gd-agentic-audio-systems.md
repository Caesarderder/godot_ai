---
name: gd-agentic-audio-systems
description: "Use when applying the godot-audio-systems capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-audio-systems

This Builda skill adapts the upstream `godot-audio-systems` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **audio-system**

## Use

1. Inspect the current project and select the smallest relevant canonical owner.
2. Apply this capability through existing Builda project, architecture, resource, save/load, asset, and review rules.
3. Reject native, editor-only, network-authority, credential, external-process, multithreaded, or unsupported API assumptions unless the project explicitly authorizes and validates them.
4. Verify Godot 4.6 parsing/import, Web Compatibility export, focused behavior, and the real runtime before claiming completion.

## Core protection

Do not modify or supersede **godot-project-setup**, **godot-architecture**, **gdscript-patterns**, **assets-pipeline**, **resource-pattern**, **save-load**, or **godot-code-review**. Project files, scene/UID identity, `res://`, `user://`, persistence, asset provenance, and review policy remain owned there.

Source classification: [GD-Agentic-Skills](https://github.com/thedivergentai/GD-Agentic-Skills), reviewed revision `42eea91671adb27b2822be94aa46345517803ffb`; upstream license: LGPL-3.0 (license text is not bundled).

<!-- builda-script-index:start -->

## Builda script prototypes

Inspect only the prototypes relevant to the current task. These files are preserved from the pinned upstream revision, but they are not pre-approved for direct execution or bulk copying; adapt them to Godot 4.6.x, GDScript, Web, Compatibility rendering, single-thread execution, and the current project boundary.

- [`audio_adaptive_music_player.gd`](../scripts/gd-agentic-audio-systems/audio_adaptive_music_player.gd)
- [`audio_bus_ducker_logic.gd`](../scripts/gd-agentic-audio-systems/audio_bus_ducker_logic.gd)
- [`audio_bus_manager.gd`](../scripts/gd-agentic-audio-systems/audio_bus_manager.gd)
- [`audio_environmental_reverb_zone.gd`](../scripts/gd-agentic-audio-systems/audio_environmental_reverb_zone.gd)
- [`audio_footstep_surface_selector.gd`](../scripts/gd-agentic-audio-systems/audio_footstep_surface_selector.gd)
- [`audio_interactive_music_manager.gd`](../scripts/gd-agentic-audio-systems/audio_interactive_music_manager.gd)
- [`audio_linear_volume_interpolator.gd`](../scripts/gd-agentic-audio-systems/audio_linear_volume_interpolator.gd)
- [`audio_manager.gd`](../scripts/gd-agentic-audio-systems/audio_manager.gd)
- [`audio_occlusion_raycast.gd`](../scripts/gd-agentic-audio-systems/audio_occlusion_raycast.gd)
- [`audio_procedural_generator_synth.gd`](../scripts/gd-agentic-audio-systems/audio_procedural_generator_synth.gd)
- [`audio_reactive_visualizer_component.gd`](../scripts/gd-agentic-audio-systems/audio_reactive_visualizer_component.gd)
- [`audio_visualizer.gd`](../scripts/gd-agentic-audio-systems/audio_visualizer.gd)
- [`audio_voice_limiter_manager.gd`](../scripts/gd-agentic-audio-systems/audio_voice_limiter_manager.gd)
- [`audio_voice_pool_manager.gd`](../scripts/gd-agentic-audio-systems/audio_voice_pool_manager.gd)
- [`interactive_music_graph.gd`](../scripts/gd-agentic-audio-systems/interactive_music_graph.gd)
- [`subtitle_sync_system.gd`](../scripts/gd-agentic-audio-systems/subtitle_sync_system.gd)

<!-- builda-script-index:end -->

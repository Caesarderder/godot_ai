---
name: gd-agentic-animation-player
description: "Use when applying the godot-animation-player capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-animation-player

This Builda skill adapts the upstream `godot-animation-player` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **animation-system**

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

- [`active_animation_culler.gd`](../scripts/gd-agentic-animation-player/active_animation_culler.gd)
- [`animation_sequencer.gd`](../scripts/gd-agentic-animation-player/animation_sequencer.gd)
- [`audio_sync_tracks.gd`](../scripts/gd-agentic-animation-player/audio_sync_tracks.gd)
- [`bezier_curve_extraction.gd`](../scripts/gd-agentic-animation-player/bezier_curve_extraction.gd)
- [`character_part_swapper_tracks.gd`](../scripts/gd-agentic-animation-player/character_part_swapper_tracks.gd)
- [`dynamic_shader_animation.gd`](../scripts/gd-agentic-animation-player/dynamic_shader_animation.gd)
- [`method_track_logic.gd`](../scripts/gd-agentic-animation-player/method_track_logic.gd)
- [`precise_audio_sync.gd`](../scripts/gd-agentic-animation-player/precise_audio_sync.gd)
- [`procedural_track_modifier.gd`](../scripts/gd-agentic-animation-player/procedural_track_modifier.gd)
- [`programmatic_anim.gd`](../scripts/gd-agentic-animation-player/programmatic_anim.gd)
- [`reset_track_orchestrator.gd`](../scripts/gd-agentic-animation-player/reset_track_orchestrator.gd)
- [`root_motion_physics_sync.gd`](../scripts/gd-agentic-animation-player/root_motion_physics_sync.gd)
- [`runtime_anim_lib_swapper.gd`](../scripts/gd-agentic-animation-player/runtime_anim_lib_swapper.gd)

<!-- builda-script-index:end -->

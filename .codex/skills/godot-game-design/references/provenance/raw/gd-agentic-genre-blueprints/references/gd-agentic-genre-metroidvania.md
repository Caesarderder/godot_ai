---
name: gd-agentic-genre-metroidvania
description: "Use when applying the godot-genre-metroidvania capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-metroidvania

This Builda skill adapts the upstream `godot-genre-metroidvania` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-design-role
- Canonical Builda owners: **game-design**, **game-prototype**

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

- [`ability_state_machine.gd`](../scripts/gd-agentic-genre-metroidvania/ability_state_machine.gd)
- [`ability_unlock_resource.gd`](../scripts/gd-agentic-genre-metroidvania/ability_unlock_resource.gd)
- [`background_room_streamer.gd`](../scripts/gd-agentic-genre-metroidvania/background_room_streamer.gd)
- [`decoupled_hazard_logic.gd`](../scripts/gd-agentic-genre-metroidvania/decoupled_hazard_logic.gd)
- [`fast_travel_system.gd`](../scripts/gd-agentic-genre-metroidvania/fast_travel_system.gd)
- [`fast_wall_detector.gd`](../scripts/gd-agentic-genre-metroidvania/fast_wall_detector.gd)
- [`metroid_game_state.gd`](../scripts/gd-agentic-genre-metroidvania/metroid_game_state.gd)
- [`minimap_fog.gd`](../scripts/gd-agentic-genre-metroidvania/minimap_fog.gd)
- [`minimap_fog_manager.gd`](../scripts/gd-agentic-genre-metroidvania/minimap_fog_manager.gd)
- [`minimap_fog_revealer.gd`](../scripts/gd-agentic-genre-metroidvania/minimap_fog_revealer.gd)
- [`persistent_progression_system.gd`](../scripts/gd-agentic-genre-metroidvania/persistent_progression_system.gd)
- [`platformer_jump_buffer.gd`](../scripts/gd-agentic-genre-metroidvania/platformer_jump_buffer.gd)
- [`progression_gate_manager.gd`](../scripts/gd-agentic-genre-metroidvania/progression_gate_manager.gd)
- [`progression_manager.gd`](../scripts/gd-agentic-genre-metroidvania/progression_manager.gd)
- [`room_metadata.gd`](../scripts/gd-agentic-genre-metroidvania/room_metadata.gd)
- [`safe_scene_switcher.gd`](../scripts/gd-agentic-genre-metroidvania/safe_scene_switcher.gd)
- [`save_station_broadcast.gd`](../scripts/gd-agentic-genre-metroidvania/save_station_broadcast.gd)
- [`smooth_room_camera_transition.gd`](../scripts/gd-agentic-genre-metroidvania/smooth_room_camera_transition.gd)

<!-- builda-script-index:end -->

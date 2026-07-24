---
name: gd-agentic-genre-racing
description: "Use when applying the godot-genre-racing capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-racing

This Builda skill adapts the upstream `godot-genre-racing` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`arcade_vehicle_controller.gd`](../scripts/gd-agentic-genre-racing/arcade_vehicle_controller.gd)
- [`arcade_vehicle_physics.gd`](../scripts/gd-agentic-genre-racing/arcade_vehicle_physics.gd)
- [`engine_audio_controller.gd`](../scripts/gd-agentic-genre-racing/engine_audio_controller.gd)
- [`force_feedback_router.gd`](../scripts/gd-agentic-genre-racing/force_feedback_router.gd)
- [`ghost_recorder.gd`](../scripts/gd-agentic-genre-racing/ghost_recorder.gd)
- [`lap_checkpoint_manager.gd`](../scripts/gd-agentic-genre-racing/lap_checkpoint_manager.gd)
- [`lap_tracker.gd`](../scripts/gd-agentic-genre-racing/lap_tracker.gd)
- [`minimap_icon_projector.gd`](../scripts/gd-agentic-genre-racing/minimap_icon_projector.gd)
- [`racing_checkpoint.gd`](../scripts/gd-agentic-genre-racing/racing_checkpoint.gd)
- [`raycast_suspension.gd`](../scripts/gd-agentic-genre-racing/raycast_suspension.gd)
- [`raycast_vehicle_controller.gd`](../scripts/gd-agentic-genre-racing/raycast_vehicle_controller.gd)
- [`skid_mark_emitter.gd`](../scripts/gd-agentic-genre-racing/skid_mark_emitter.gd)
- [`slipstream_handler.gd`](../scripts/gd-agentic-genre-racing/slipstream_handler.gd)
- [`spline_ai_controller.gd`](../scripts/gd-agentic-genre-racing/spline_ai_controller.gd)
- [`spline_track_spawner.gd`](../scripts/gd-agentic-genre-racing/spline_track_spawner.gd)

<!-- builda-script-index:end -->

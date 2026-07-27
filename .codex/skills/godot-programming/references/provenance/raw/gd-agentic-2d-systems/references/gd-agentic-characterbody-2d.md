---
name: gd-agentic-characterbody-2d
description: "Use when applying the godot-characterbody-2d capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-characterbody-2d

This Builda skill adapts the upstream `godot-characterbody-2d` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **player-controller**

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

- [`aerial_drift_acceleration.gd`](../scripts/gd-agentic-characterbody-2d/aerial_drift_acceleration.gd)
- [`ceiling_bonk_detection.gd`](../scripts/gd-agentic-characterbody-2d/ceiling_bonk_detection.gd)
- [`dash_controller.gd`](../scripts/gd-agentic-characterbody-2d/dash_controller.gd)
- [`dash_state_controller.gd`](../scripts/gd-agentic-characterbody-2d/dash_state_controller.gd)
- [`expert_physics_2d.gd`](../scripts/gd-agentic-characterbody-2d/expert_physics_2d.gd)
- [`frame_perfect_coyote_time.gd`](../scripts/gd-agentic-characterbody-2d/frame_perfect_coyote_time.gd)
- [`game_feel_profiler.gd`](../scripts/gd-agentic-characterbody-2d/game_feel_profiler.gd)
- [`impulse_response_handler.gd`](../scripts/gd-agentic-characterbody-2d/impulse_response_handler.gd)
- [`performance_character_pooling.gd`](../scripts/gd-agentic-characterbody-2d/performance_character_pooling.gd)
- [`root_motion_controller.gd`](../scripts/gd-agentic-characterbody-2d/root_motion_controller.gd)
- [`slope_stair_snapping.gd`](../scripts/gd-agentic-characterbody-2d/slope_stair_snapping.gd)
- [`subpixel_movement_rounding.gd`](../scripts/gd-agentic-characterbody-2d/subpixel_movement_rounding.gd)
- [`variable_jump_height.gd`](../scripts/gd-agentic-characterbody-2d/variable_jump_height.gd)
- [`wall_jump_controller.gd`](../scripts/gd-agentic-characterbody-2d/wall_jump_controller.gd)
- [`wall_slide_jump_refined.gd`](../scripts/gd-agentic-characterbody-2d/wall_slide_jump_refined.gd)

<!-- builda-script-index:end -->

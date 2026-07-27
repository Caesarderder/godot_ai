---
name: gd-agentic-genre-platformer
description: "Use when applying the godot-genre-platformer capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-platformer

This Builda skill adapts the upstream `godot-genre-platformer` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`advanced_platformer_controller.gd`](../scripts/gd-agentic-genre-platformer/advanced_platformer_controller.gd)
- [`checkpoint.gd`](../scripts/gd-agentic-genre-platformer/checkpoint.gd)
- [`coyote_timer.gd`](../scripts/gd-agentic-genre-platformer/coyote_timer.gd)
- [`custom_collision_slider.gd`](../scripts/gd-agentic-genre-platformer/custom_collision_slider.gd)
- [`fast_projectile_ccd.gd`](../scripts/gd-agentic-genre-platformer/fast_projectile_ccd.gd)
- [`game_feel_helper.gd`](../scripts/gd-agentic-genre-platformer/game_feel_helper.gd)
- [`jump_buffer.gd`](../scripts/gd-agentic-genre-platformer/jump_buffer.gd)
- [`ledge_grab_sensor.gd`](../scripts/gd-agentic-genre-platformer/ledge_grab_sensor.gd)
- [`one_way_drop_handler.gd`](../scripts/gd-agentic-genre-platformer/one_way_drop_handler.gd)
- [`platformer_animation_sync.gd`](../scripts/gd-agentic-genre-platformer/platformer_animation_sync.gd)
- [`platformer_camera.gd`](../scripts/gd-agentic-genre-platformer/platformer_camera.gd)
- [`platformer_controller_2d.gd`](../scripts/gd-agentic-genre-platformer/platformer_controller_2d.gd)
- [`player_ground_controller.gd`](../scripts/gd-agentic-genre-platformer/player_ground_controller.gd)
- [`speed_trail.gd`](../scripts/gd-agentic-genre-platformer/speed_trail.gd)
- [`synchronized_platform.gd`](../scripts/gd-agentic-genre-platformer/synchronized_platform.gd)
- [`variable_jump.gd`](../scripts/gd-agentic-genre-platformer/variable_jump.gd)
- [`wall_slide_sensor.gd`](../scripts/gd-agentic-genre-platformer/wall_slide_sensor.gd)

<!-- builda-script-index:end -->

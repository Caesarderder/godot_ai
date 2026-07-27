---
name: gd-agentic-2d-physics
description: "Use when applying the godot-2d-physics capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-2d-physics

This Builda skill adapts the upstream `godot-2d-physics` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **physics-system**

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

- [`collision_bitmask_helper.gd`](../scripts/gd-agentic-2d-physics/collision_bitmask_helper.gd)
- [`collision_debouncer.gd`](../scripts/gd-agentic-2d-physics/collision_debouncer.gd)
- [`collision_layer_matrix_manager.gd`](../scripts/gd-agentic-2d-physics/collision_layer_matrix_manager.gd)
- [`collision_setup.gd`](../scripts/gd-agentic-2d-physics/collision_setup.gd)
- [`collision_visual_debugger.gd`](../scripts/gd-agentic-2d-physics/collision_visual_debugger.gd)
- [`compound_body_sync.gd`](../scripts/gd-agentic-2d-physics/compound_body_sync.gd)
- [`continuous_collision_detection.gd`](../scripts/gd-agentic-2d-physics/continuous_collision_detection.gd)
- [`custom_gravity_area.gd`](../scripts/gd-agentic-2d-physics/custom_gravity_area.gd)
- [`custom_gravity_override.gd`](../scripts/gd-agentic-2d-physics/custom_gravity_override.gd)
- [`custom_physics.gd`](../scripts/gd-agentic-2d-physics/custom_physics.gd)
- [`custom_physics_2d.gd`](../scripts/gd-agentic-2d-physics/custom_physics_2d.gd)
- [`jitter_interpolation_fix.gd`](../scripts/gd-agentic-2d-physics/jitter_interpolation_fix.gd)
- [`move_and_collide_precision.gd`](../scripts/gd-agentic-2d-physics/move_and_collide_precision.gd)
- [`performance_batch_mover.gd`](../scripts/gd-agentic-2d-physics/performance_batch_mover.gd)
- [`physics_direct_query.gd`](../scripts/gd-agentic-2d-physics/physics_direct_query.gd)
- [`physics_direct_space_query.gd`](../scripts/gd-agentic-2d-physics/physics_direct_space_query.gd)
- [`physics_interpolation_smoothing.gd`](../scripts/gd-agentic-2d-physics/physics_interpolation_smoothing.gd)
- [`physics_queries.gd`](../scripts/gd-agentic-2d-physics/physics_queries.gd)
- [`physics_query_cache.gd`](../scripts/gd-agentic-2d-physics/physics_query_cache.gd)
- [`physics_server_direct_body.gd`](../scripts/gd-agentic-2d-physics/physics_server_direct_body.gd)
- [`physics_server_swarm.gd`](../scripts/gd-agentic-2d-physics/physics_server_swarm.gd)
- [`raycast_hit_prediction.gd`](../scripts/gd-agentic-2d-physics/raycast_hit_prediction.gd)
- [`raycast_vision_stack.gd`](../scripts/gd-agentic-2d-physics/raycast_vision_stack.gd)
- [`safe_rigidbody_state.gd`](../scripts/gd-agentic-2d-physics/safe_rigidbody_state.gd)
- [`shapecast_aoe.gd`](../scripts/gd-agentic-2d-physics/shapecast_aoe.gd)
- [`shapecast_aoe_detection.gd`](../scripts/gd-agentic-2d-physics/shapecast_aoe_detection.gd)
- [`substepping_logic.gd`](../scripts/gd-agentic-2d-physics/substepping_logic.gd)

<!-- builda-script-index:end -->

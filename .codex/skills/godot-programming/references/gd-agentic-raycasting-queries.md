---
name: gd-agentic-raycasting-queries
description: "Use when applying the godot-raycasting-queries capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-raycasting-queries

This Builda skill adapts the upstream `godot-raycasting-queries` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`direct_space_state_raycast.gd`](../scripts/gd-agentic-raycasting-queries/direct_space_state_raycast.gd)
- [`field_of_view_scanner.gd`](../scripts/gd-agentic-raycasting-queries/field_of_view_scanner.gd)
- [`mouse_pick_3d_query.gd`](../scripts/gd-agentic-raycasting-queries/mouse_pick_3d_query.gd)
- [`multiple_hit_piercing_ray.gd`](../scripts/gd-agentic-raycasting-queries/multiple_hit_piercing_ray.gd)
- [`point_in_shape_query.gd`](../scripts/gd-agentic-raycasting-queries/point_in_shape_query.gd)
- [`query_exclusion_optimization.gd`](../scripts/gd-agentic-raycasting-queries/query_exclusion_optimization.gd)
- [`raycast_reflection_logic.gd`](../scripts/gd-agentic-raycasting-queries/raycast_reflection_logic.gd)
- [`rest_info_3d_stuck_fix.gd`](../scripts/gd-agentic-raycasting-queries/rest_info_3d_stuck_fix.gd)
- [`shapecast_ground_detection.gd`](../scripts/gd-agentic-raycasting-queries/shapecast_ground_detection.gd)
- [`water_buoyancy_surface_calc.gd`](../scripts/gd-agentic-raycasting-queries/water_buoyancy_surface_calc.gd)

<!-- builda-script-index:end -->

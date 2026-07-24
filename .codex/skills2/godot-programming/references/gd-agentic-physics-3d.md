---
name: gd-agentic-physics-3d
description: "Use when applying the godot-physics-3d capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-physics-3d

This Builda skill adapts the upstream `godot-physics-3d` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`custom_gravity_well_3d.gd`](../scripts/gd-agentic-physics-3d/custom_gravity_well_3d.gd)
- [`hover_constraint_3d.gd`](../scripts/gd-agentic-physics-3d/hover_constraint_3d.gd)
- [`joint_3d_breakage_logic.gd`](../scripts/gd-agentic-physics-3d/joint_3d_breakage_logic.gd)
- [`kinematic_3d_stairs_logic.gd`](../scripts/gd-agentic-physics-3d/kinematic_3d_stairs_logic.gd)
- [`physics_ccd_3d_projectile.gd`](../scripts/gd-agentic-physics-3d/physics_ccd_3d_projectile.gd)
- [`physics_layers_3d_config.gd`](../scripts/gd-agentic-physics-3d/physics_layers_3d_config.gd)
- [`physics_server_3d_bullets.gd`](../scripts/gd-agentic-physics-3d/physics_server_3d_bullets.gd)
- [`ragdoll_blender.gd`](../scripts/gd-agentic-physics-3d/ragdoll_blender.gd)
- [`ragdoll_manager.gd`](../scripts/gd-agentic-physics-3d/ragdoll_manager.gd)
- [`ray_query_3d_vision.gd`](../scripts/gd-agentic-physics-3d/ray_query_3d_vision.gd)
- [`raycast_visualizer.gd`](../scripts/gd-agentic-physics-3d/raycast_visualizer.gd)
- [`shapecast_3d_ground_check.gd`](../scripts/gd-agentic-physics-3d/shapecast_3d_ground_check.gd)
- [`soft_body_3d_interaction.gd`](../scripts/gd-agentic-physics-3d/soft_body_3d_interaction.gd)
- [`vehicle_simulation_tuning.gd`](../scripts/gd-agentic-physics-3d/vehicle_simulation_tuning.gd)

<!-- builda-script-index:end -->

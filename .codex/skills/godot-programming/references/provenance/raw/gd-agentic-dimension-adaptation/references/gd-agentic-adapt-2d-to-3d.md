---
name: gd-agentic-adapt-2d-to-3d
description: "Use when applying the godot-adapt-2d-to-3d capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-adapt-2d-to-3d

This Builda skill adapts the upstream `godot-adapt-2d-to-3d` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-programming-role
- Canonical Builda owners: **game-technical-design**, **godot-code-review**

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

- [`adapt_2d_to_3d_patterns.gd`](../scripts/gd-agentic-adapt-2d-to-3d/adapt_2d_to_3d_patterns.gd)
- [`characterbody3d_migration_movement.gd`](../scripts/gd-agentic-adapt-2d-to-3d/characterbody3d_migration_movement.gd)
- [`crisp_projected_ui.gd`](../scripts/gd-agentic-adapt-2d-to-3d/crisp_projected_ui.gd)
- [`light_migration_tool.gd`](../scripts/gd-agentic-adapt-2d-to-3d/light_migration_tool.gd)
- [`massive_crowd_manager.gd`](../scripts/gd-agentic-adapt-2d-to-3d/massive_crowd_manager.gd)
- [`navigation_bridge_2d5d.gd`](../scripts/gd-agentic-adapt-2d-to-3d/navigation_bridge_2d5d.gd)
- [`physics_layer_migration_checklist.gd`](../scripts/gd-agentic-adapt-2d-to-3d/physics_layer_migration_checklist.gd)
- [`spring_arm_camera_setup.gd`](../scripts/gd-agentic-adapt-2d-to-3d/spring_arm_camera_setup.gd)
- [`sprite_plane.gd`](../scripts/gd-agentic-adapt-2d-to-3d/sprite_plane.gd)
- [`vector_mapping.gd`](../scripts/gd-agentic-adapt-2d-to-3d/vector_mapping.gd)

<!-- builda-script-index:end -->

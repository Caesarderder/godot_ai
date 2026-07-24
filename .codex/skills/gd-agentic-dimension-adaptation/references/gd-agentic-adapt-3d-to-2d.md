---
name: gd-agentic-adapt-3d-to-2d
description: "Use when applying the godot-adapt-3d-to-2d capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-adapt-3d-to-2d

This Builda skill adapts the upstream `godot-adapt-3d-to-2d` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`2d_lighting_normals.gd`](../scripts/gd-agentic-adapt-3d-to-2d/2d_lighting_normals.gd)
- [`adapt_3d_to_2d_patterns.gd`](../scripts/gd-agentic-adapt-3d-to-2d/adapt_3d_to_2d_patterns.gd)
- [`billboard_sprite_manager.gd`](../scripts/gd-agentic-adapt-3d-to-2d/billboard_sprite_manager.gd)
- [`depth_sorting_y_sort.gd`](../scripts/gd-agentic-adapt-3d-to-2d/depth_sorting_y_sort.gd)
- [`directional_sprite_resolver.gd`](../scripts/gd-agentic-adapt-3d-to-2d/directional_sprite_resolver.gd)
- [`fake_3d_shadows.gd`](../scripts/gd-agentic-adapt-3d-to-2d/fake_3d_shadows.gd)
- [`grid_nav_bridge.gd`](../scripts/gd-agentic-adapt-3d-to-2d/grid_nav_bridge.gd)
- [`hitbox_depth_manager.gd`](../scripts/gd-agentic-adapt-3d-to-2d/hitbox_depth_manager.gd)
- [`isometric_math_core.gd`](../scripts/gd-agentic-adapt-3d-to-2d/isometric_math_core.gd)
- [`jump_z_axis_sim.gd`](../scripts/gd-agentic-adapt-3d-to-2d/jump_z_axis_sim.gd)
- [`model_to_sprite_bake.gd`](../scripts/gd-agentic-adapt-3d-to-2d/model_to_sprite_bake.gd)
- [`nav_region_flattening.gd`](../scripts/gd-agentic-adapt-3d-to-2d/nav_region_flattening.gd)
- [`ortho_simulation.gd`](../scripts/gd-agentic-adapt-3d-to-2d/ortho_simulation.gd)
- [`ortho_to_perspective_fx.gd`](../scripts/gd-agentic-adapt-3d-to-2d/ortho_to_perspective_fx.gd)
- [`parallax_depth_camera.gd`](../scripts/gd-agentic-adapt-3d-to-2d/parallax_depth_camera.gd)
- [`projection_utils.gd`](../scripts/gd-agentic-adapt-3d-to-2d/projection_utils.gd)

<!-- builda-script-index:end -->

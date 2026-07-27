---
name: gd-agentic-3d-world-building
description: "Use when applying the godot-3d-world-building capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-3d-world-building

This Builda skill adapts the upstream `godot-3d-world-building` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **3d-essentials**, **game-level-design**

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

- [`collision_gen.gd`](../scripts/gd-agentic-3d-world-building/collision_gen.gd)
- [`collision_generator.gd`](../scripts/gd-agentic-3d-world-building/collision_generator.gd)
- [`csg_bake_tool.gd`](../scripts/gd-agentic-3d-world-building/csg_bake_tool.gd)
- [`grid_map_logic_manager.gd`](../scripts/gd-agentic-3d-world-building/grid_map_logic_manager.gd)
- [`grid_map_manager.gd`](../scripts/gd-agentic-3d-world-building/grid_map_manager.gd)
- [`gridmap_runtime_builder.gd`](../scripts/gd-agentic-3d-world-building/gridmap_runtime_builder.gd)
- [`lod_manager.gd`](../scripts/gd-agentic-3d-world-building/lod_manager.gd)
- [`occlusion_setup.gd`](../scripts/gd-agentic-3d-world-building/occlusion_setup.gd)
- [`safe_csg_baking.gd`](../scripts/gd-agentic-3d-world-building/safe_csg_baking.gd)
- [`world_streamer.gd`](../scripts/gd-agentic-3d-world-building/world_streamer.gd)

<!-- builda-script-index:end -->

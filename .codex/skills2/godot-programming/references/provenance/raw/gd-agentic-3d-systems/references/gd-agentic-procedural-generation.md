---
name: gd-agentic-procedural-generation
description: "Use when applying the godot-procedural-generation capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-procedural-generation

This Builda skill adapts the upstream `godot-procedural-generation` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **procedural-generation**

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

- [`bsp_tree_rooms.gd`](../scripts/gd-agentic-procedural-generation/bsp_tree_rooms.gd)
- [`cellular_automata_dungeon.gd`](../scripts/gd-agentic-procedural-generation/cellular_automata_dungeon.gd)
- [`drunknard_walk_path.gd`](../scripts/gd-agentic-procedural-generation/drunknard_walk_path.gd)
- [`dungeon_generator.gd`](../scripts/gd-agentic-procedural-generation/dungeon_generator.gd)
- [`fast_noise_noise2d_master.gd`](../scripts/gd-agentic-procedural-generation/fast_noise_noise2d_master.gd)
- [`l_system_tree_gen.gd`](../scripts/gd-agentic-procedural-generation/l_system_tree_gen.gd)
- [`marching_squares_metaballs.gd`](../scripts/gd-agentic-procedural-generation/marching_squares_metaballs.gd)
- [`mesh_gen_infinite_terrain.gd`](../scripts/gd-agentic-procedural-generation/mesh_gen_infinite_terrain.gd)
- [`multi_threaded_chunk_gen.gd`](../scripts/gd-agentic-procedural-generation/multi_threaded_chunk_gen.gd)
- [`poisson_disk_sampling_2d.gd`](../scripts/gd-agentic-procedural-generation/poisson_disk_sampling_2d.gd)
- [`proc_gen_graph_layout.gd`](../scripts/gd-agentic-procedural-generation/proc_gen_graph_layout.gd)
- [`proc_gen_marching_cubes_base.gd`](../scripts/gd-agentic-procedural-generation/proc_gen_marching_cubes_base.gd)
- [`proc_gen_seed_history.gd`](../scripts/gd-agentic-procedural-generation/proc_gen_seed_history.gd)
- [`wave_function_collapse_lite.gd`](../scripts/gd-agentic-procedural-generation/wave_function_collapse_lite.gd)
- [`wfc_level_generator.gd`](../scripts/gd-agentic-procedural-generation/wfc_level_generator.gd)

<!-- builda-script-index:end -->

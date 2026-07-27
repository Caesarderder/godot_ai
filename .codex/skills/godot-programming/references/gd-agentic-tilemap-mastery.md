---
name: gd-agentic-tilemap-mastery
description: "Use when applying the godot-tilemap-mastery capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-tilemap-mastery

This Builda skill adapts the upstream `godot-tilemap-mastery` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`destructible_tile_logic.gd`](../scripts/gd-agentic-tilemap-mastery/destructible_tile_logic.gd)
- [`fast_metadata_cache.gd`](../scripts/gd-agentic-tilemap-mastery/fast_metadata_cache.gd)
- [`gameplay_data_query.gd`](../scripts/gd-agentic-tilemap-mastery/gameplay_data_query.gd)
- [`nav_mesh_teleport_fix.gd`](../scripts/gd-agentic-tilemap-mastery/nav_mesh_teleport_fix.gd)
- [`physics_shape_interaction.gd`](../scripts/gd-agentic-tilemap-mastery/physics_shape_interaction.gd)
- [`procedural_chunk_batcher.gd`](../scripts/gd-agentic-tilemap-mastery/procedural_chunk_batcher.gd)
- [`sorting_Z_layering.gd`](../scripts/gd-agentic-tilemap-mastery/sorting_Z_layering.gd)
- [`terrain_autotile.gd`](../scripts/gd-agentic-tilemap-mastery/terrain_autotile.gd)
- [`terrain_path_painter.gd`](../scripts/gd-agentic-tilemap-mastery/terrain_path_painter.gd)
- [`tile_pattern_stamper.gd`](../scripts/gd-agentic-tilemap-mastery/tile_pattern_stamper.gd)
- [`tilemap_chunking.gd`](../scripts/gd-agentic-tilemap-mastery/tilemap_chunking.gd)
- [`tilemap_data_manager.gd`](../scripts/gd-agentic-tilemap-mastery/tilemap_data_manager.gd)
- [`tilemap_layer_v43_upgrade.gd`](../scripts/gd-agentic-tilemap-mastery/tilemap_layer_v43_upgrade.gd)

<!-- builda-script-index:end -->

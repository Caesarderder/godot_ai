---
name: gd-agentic-genre-open-world
description: "Use when applying the godot-genre-open-world capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-open-world

This Builda skill adapts the upstream `godot-genre-open-world` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`async_chunk_loader.gd`](../scripts/gd-agentic-genre-open-world/async_chunk_loader.gd)
- [`binary_save_manager.gd`](../scripts/gd-agentic-genre-open-world/binary_save_manager.gd)
- [`chunk_limited_pathfinder.gd`](../scripts/gd-agentic-genre-open-world/chunk_limited_pathfinder.gd)
- [`dynamic_lod_adjuster.gd`](../scripts/gd-agentic-genre-open-world/dynamic_lod_adjuster.gd)
- [`floating_origin_shifter.gd`](../scripts/gd-agentic-genre-open-world/floating_origin_shifter.gd)
- [`global_state.gd`](../scripts/gd-agentic-genre-open-world/global_state.gd)
- [`group_weather_broadcaster.gd`](../scripts/gd-agentic-genre-open-world/group_weather_broadcaster.gd)
- [`hlod_visibility_config.gd`](../scripts/gd-agentic-genre-open-world/hlod_visibility_config.gd)
- [`landscape_height_query.gd`](../scripts/gd-agentic-genre-open-world/landscape_height_query.gd)
- [`lod_logic_enabler.gd`](../scripts/gd-agentic-genre-open-world/lod_logic_enabler.gd)
- [`multimesh_foliage_manager.gd`](../scripts/gd-agentic-genre-open-world/multimesh_foliage_manager.gd)
- [`server_prop_spawner.gd`](../scripts/gd-agentic-genre-open-world/server_prop_spawner.gd)
- [`world_origin_shifter.gd`](../scripts/gd-agentic-genre-open-world/world_origin_shifter.gd)
- [`world_streamer.gd`](../scripts/gd-agentic-genre-open-world/world_streamer.gd)

<!-- builda-script-index:end -->

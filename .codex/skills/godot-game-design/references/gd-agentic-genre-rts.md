---
name: gd-agentic-genre-rts
description: "Use when applying the godot-genre-rts capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-rts

This Builda skill adapts the upstream `godot-genre-rts` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`building_grid_astar.gd`](../scripts/gd-agentic-genre-rts/building_grid_astar.gd)
- [`crowd_navigation_unit.gd`](../scripts/gd-agentic-genre-rts/crowd_navigation_unit.gd)
- [`fog_of_war_tile_mask.gd`](../scripts/gd-agentic-genre-rts/fog_of_war_tile_mask.gd)
- [`global_economy_manager.gd`](../scripts/gd-agentic-genre-rts/global_economy_manager.gd)
- [`navigation_mask_helper.gd`](../scripts/gd-agentic-genre-rts/navigation_mask_helper.gd)
- [`rendering_ghost_spawner.gd`](../scripts/gd-agentic-genre-rts/rendering_ghost_spawner.gd)
- [`rts_army_manager.gd`](../scripts/gd-agentic-genre-rts/rts_army_manager.gd)
- [`rts_formation_manager.gd`](../scripts/gd-agentic-genre-rts/rts_formation_manager.gd)
- [`rts_group_commander.gd`](../scripts/gd-agentic-genre-rts/rts_group_commander.gd)
- [`rts_massive_unit_renderer.gd`](../scripts/gd-agentic-genre-rts/rts_massive_unit_renderer.gd)
- [`rts_path_query_pool.gd`](../scripts/gd-agentic-genre-rts/rts_path_query_pool.gd)
- [`rts_selection_overlay.gd`](../scripts/gd-agentic-genre-rts/rts_selection_overlay.gd)
- [`rts_targeting_logic.gd`](../scripts/gd-agentic-genre-rts/rts_targeting_logic.gd)
- [`rts_unit.gd`](../scripts/gd-agentic-genre-rts/rts_unit.gd)
- [`rts_unit_stat_duplicator.gd`](../scripts/gd-agentic-genre-rts/rts_unit_stat_duplicator.gd)
- [`selection_manager_marquee_2d.gd`](../scripts/gd-agentic-genre-rts/selection_manager_marquee_2d.gd)
- [`selection_manager_raycast_3d.gd`](../scripts/gd-agentic-genre-rts/selection_manager_raycast_3d.gd)

<!-- builda-script-index:end -->

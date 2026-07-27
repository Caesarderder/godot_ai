---
name: gd-agentic-genre-roguelike
description: "Use when applying the godot-genre-roguelike capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-roguelike

This Builda skill adapts the upstream `godot-genre-roguelike` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`astar_grid_handler.gd`](../scripts/gd-agentic-genre-roguelike/astar_grid_handler.gd)
- [`async_turn_manager.gd`](../scripts/gd-agentic-genre-roguelike/async_turn_manager.gd)
- [`director_ai.gd`](../scripts/gd-agentic-genre-roguelike/director_ai.gd)
- [`dungeon_generator.gd`](../scripts/gd-agentic-genre-roguelike/dungeon_generator.gd)
- [`dungeon_generator_walker.gd`](../scripts/gd-agentic-genre-roguelike/dungeon_generator_walker.gd)
- [`example_relic_vampirism.gd`](../scripts/gd-agentic-genre-roguelike/example_relic_vampirism.gd)
- [`fog_of_war_masker.gd`](../scripts/gd-agentic-genre-roguelike/fog_of_war_masker.gd)
- [`fov_raycast_calculator.gd`](../scripts/gd-agentic-genre-roguelike/fov_raycast_calculator.gd)
- [`json_state_serializer.gd`](../scripts/gd-agentic-genre-roguelike/json_state_serializer.gd)
- [`meta_progression_manager.gd`](../scripts/gd-agentic-genre-roguelike/meta_progression_manager.gd)
- [`meta_progression_resource.gd`](../scripts/gd-agentic-genre-roguelike/meta_progression_resource.gd)
- [`meta_stats_resource.gd`](../scripts/gd-agentic-genre-roguelike/meta_stats_resource.gd)
- [`move_command_object.gd`](../scripts/gd-agentic-genre-roguelike/move_command_object.gd)
- [`noise_dungeon_generator.gd`](../scripts/gd-agentic-genre-roguelike/noise_dungeon_generator.gd)
- [`roguelike_patterns.gd`](../scripts/gd-agentic-genre-roguelike/roguelike_patterns.gd)
- [`room_assembler.gd`](../scripts/gd-agentic-genre-roguelike/room_assembler.gd)
- [`run_manager.gd`](../scripts/gd-agentic-genre-roguelike/run_manager.gd)
- [`seeded_rng_resource.gd`](../scripts/gd-agentic-genre-roguelike/seeded_rng_resource.gd)
- [`synergy_manager.gd`](../scripts/gd-agentic-genre-roguelike/synergy_manager.gd)
- [`turn_manager_decoupled.gd`](../scripts/gd-agentic-genre-roguelike/turn_manager_decoupled.gd)
- [`weighted_loot_table.gd`](../scripts/gd-agentic-genre-roguelike/weighted_loot_table.gd)

<!-- builda-script-index:end -->

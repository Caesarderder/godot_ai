---
name: gd-agentic-genre-action-rpg
description: "Use when applying the godot-genre-action-rpg capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-action-rpg

This Builda skill adapts the upstream `godot-genre-action-rpg` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`animation_condition_sync.gd`](../scripts/gd-agentic-genre-action-rpg/animation_condition_sync.gd)
- [`aoe_group_broadcaster.gd`](../scripts/gd-agentic-genre-action-rpg/aoe_group_broadcaster.gd)
- [`aoe_physics_query.gd`](../scripts/gd-agentic-genre-action-rpg/aoe_physics_query.gd)
- [`base_stat_resource.gd`](../scripts/gd-agentic-genre-action-rpg/base_stat_resource.gd)
- [`character_stats_resource.gd`](../scripts/gd-agentic-genre-action-rpg/character_stats_resource.gd)
- [`combat_damage_calculator.gd`](../scripts/gd-agentic-genre-action-rpg/combat_damage_calculator.gd)
- [`combat_event_bus.gd`](../scripts/gd-agentic-genre-action-rpg/combat_event_bus.gd)
- [`combat_log_connector.gd`](../scripts/gd-agentic-genre-action-rpg/combat_log_connector.gd)
- [`cooldown_coroutine.gd`](../scripts/gd-agentic-genre-action-rpg/cooldown_coroutine.gd)
- [`damage_label_manager.gd`](../scripts/gd-agentic-genre-action-rpg/damage_label_manager.gd)
- [`deep_stat_duplicator.gd`](../scripts/gd-agentic-genre-action-rpg/deep_stat_duplicator.gd)
- [`duck_typed_hitbox.gd`](../scripts/gd-agentic-genre-action-rpg/duck_typed_hitbox.gd)
- [`enemy_area_scaler.gd`](../scripts/gd-agentic-genre-action-rpg/enemy_area_scaler.gd)
- [`entity_stat_duplicator.gd`](../scripts/gd-agentic-genre-action-rpg/entity_stat_duplicator.gd)
- [`health_component.gd`](../scripts/gd-agentic-genre-action-rpg/health_component.gd)
- [`hierarchical_state_base.gd`](../scripts/gd-agentic-genre-action-rpg/hierarchical_state_base.gd)
- [`high_speed_aggro_broadcaster.gd`](../scripts/gd-agentic-genre-action-rpg/high_speed_aggro_broadcaster.gd)
- [`hitbox_component.gd`](../scripts/gd-agentic-genre-action-rpg/hitbox_component.gd)
- [`leveling_table.gd`](../scripts/gd-agentic-genre-action-rpg/leveling_table.gd)
- [`loot_generator.gd`](../scripts/gd-agentic-genre-action-rpg/loot_generator.gd)
- [`signal_combat_decoupler.gd`](../scripts/gd-agentic-genre-action-rpg/signal_combat_decoupler.gd)
- [`stat_reduction_solver.gd`](../scripts/gd-agentic-genre-action-rpg/stat_reduction_solver.gd)
- [`telegraphed_enemy.gd`](../scripts/gd-agentic-genre-action-rpg/telegraphed_enemy.gd)
- [`threaded_inventory_loader.gd`](../scripts/gd-agentic-genre-action-rpg/threaded_inventory_loader.gd)
- [`typed_inventory_storage.gd`](../scripts/gd-agentic-genre-action-rpg/typed_inventory_storage.gd)

<!-- builda-script-index:end -->

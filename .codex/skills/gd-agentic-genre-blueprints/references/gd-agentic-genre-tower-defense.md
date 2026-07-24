---
name: gd-agentic-genre-tower-defense
description: "Use when applying the godot-genre-tower-defense capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-tower-defense

This Builda skill adapts the upstream `godot-genre-tower-defense` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`burst_search_tower.gd`](../scripts/gd-agentic-genre-tower-defense/burst_search_tower.gd)
- [`grid_path_validator.gd`](../scripts/gd-agentic-genre-tower-defense/grid_path_validator.gd)
- [`homing_projectile_3d.gd`](../scripts/gd-agentic-genre-tower-defense/homing_projectile_3d.gd)
- [`organic_enemy_movement.gd`](../scripts/gd-agentic-genre-tower-defense/organic_enemy_movement.gd)
- [`tower.gd`](../scripts/gd-agentic-genre-tower-defense/tower.gd)
- [`tower_defense_patterns.gd`](../scripts/gd-agentic-genre-tower-defense/tower_defense_patterns.gd)
- [`tower_targeting_system.gd`](../scripts/gd-agentic-genre-tower-defense/tower_targeting_system.gd)
- [`wave_manager.gd`](../scripts/gd-agentic-genre-tower-defense/wave_manager.gd)
- [`wave_resource_spawner.gd`](../scripts/gd-agentic-genre-tower-defense/wave_resource_spawner.gd)

<!-- builda-script-index:end -->

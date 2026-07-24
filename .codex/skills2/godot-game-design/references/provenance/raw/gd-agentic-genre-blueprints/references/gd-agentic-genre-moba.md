---
name: gd-agentic-genre-moba
description: "Use when applying the godot-genre-moba capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-moba

This Builda skill adapts the upstream `godot-genre-moba` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`ability_ui_binder.gd`](../scripts/gd-agentic-genre-moba/ability_ui_binder.gd)
- [`async_arena_baker.gd`](../scripts/gd-agentic-genre-moba/async_arena_baker.gd)
- [`decoupled_ability_damage.gd`](../scripts/gd-agentic-genre-moba/decoupled_ability_damage.gd)
- [`fog_grid_mask.gd`](../scripts/gd-agentic-genre-moba/fog_grid_mask.gd)
- [`fog_visibility_check.gd`](../scripts/gd-agentic-genre-moba/fog_visibility_check.gd)
- [`hero_net_sync.gd`](../scripts/gd-agentic-genre-moba/hero_net_sync.gd)
- [`hero_state_machine.gd`](../scripts/gd-agentic-genre-moba/hero_state_machine.gd)
- [`jungle_creep.gd`](../scripts/gd-agentic-genre-moba/jungle_creep.gd)
- [`minion_flow_calculator.gd`](../scripts/gd-agentic-genre-moba/minion_flow_calculator.gd)
- [`minion_worker_pathfinder.gd`](../scripts/gd-agentic-genre-moba/minion_worker_pathfinder.gd)
- [`replay_manager.gd`](../scripts/gd-agentic-genre-moba/replay_manager.gd)
- [`server_minion_sync.gd`](../scripts/gd-agentic-genre-moba/server_minion_sync.gd)
- [`skill_shot_indicator.gd`](../scripts/gd-agentic-genre-moba/skill_shot_indicator.gd)
- [`status_effect_data.gd`](../scripts/gd-agentic-genre-moba/status_effect_data.gd)
- [`status_effect_manager.gd`](../scripts/gd-agentic-genre-moba/status_effect_manager.gd)
- [`synced_ability_controller.gd`](../scripts/gd-agentic-genre-moba/synced_ability_controller.gd)
- [`tower_priority_aggro.gd`](../scripts/gd-agentic-genre-moba/tower_priority_aggro.gd)
- [`weighted_target_selector.gd`](../scripts/gd-agentic-genre-moba/weighted_target_selector.gd)

<!-- builda-script-index:end -->

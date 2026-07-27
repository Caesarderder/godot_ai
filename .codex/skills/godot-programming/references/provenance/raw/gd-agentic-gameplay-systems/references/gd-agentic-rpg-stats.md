---
name: gd-agentic-rpg-stats
description: "Use when applying the godot-rpg-stats capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-rpg-stats

This Builda skill adapts the upstream `godot-rpg-stats` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **ability-progression**

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

- [`base_stats_resource.gd`](../scripts/gd-agentic-rpg-stats/base_stats_resource.gd)
- [`damage_formula_handler.gd`](../scripts/gd-agentic-rpg-stats/damage_formula_handler.gd)
- [`derived_stat_resource.gd`](../scripts/gd-agentic-rpg-stats/derived_stat_resource.gd)
- [`dynamic_stat_label_sync.gd`](../scripts/gd-agentic-rpg-stats/dynamic_stat_label_sync.gd)
- [`equipment_tooltip_helper.gd`](../scripts/gd-agentic-rpg-stats/equipment_tooltip_helper.gd)
- [`exp_progression_resource.gd`](../scripts/gd-agentic-rpg-stats/exp_progression_resource.gd)
- [`level_up_system.gd`](../scripts/gd-agentic-rpg-stats/level_up_system.gd)
- [`modifier_stack_stats.gd`](../scripts/gd-agentic-rpg-stats/modifier_stack_stats.gd)
- [`persistent_character_stats.gd`](../scripts/gd-agentic-rpg-stats/persistent_character_stats.gd)
- [`resource_stat_inheritance.gd`](../scripts/gd-agentic-rpg-stats/resource_stat_inheritance.gd)
- [`rpg_stat_resource.gd`](../scripts/gd-agentic-rpg-stats/rpg_stat_resource.gd)
- [`stat_modifier_stacking.gd`](../scripts/gd-agentic-rpg-stats/stat_modifier_stacking.gd)
- [`stat_resource.gd`](../scripts/gd-agentic-rpg-stats/stat_resource.gd)
- [`stats_component_reactive.gd`](../scripts/gd-agentic-rpg-stats/stats_component_reactive.gd)
- [`status_effect_data.gd`](../scripts/gd-agentic-rpg-stats/status_effect_data.gd)

<!-- builda-script-index:end -->

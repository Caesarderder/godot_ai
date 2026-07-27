---
name: gd-agentic-resource-data-patterns
description: "Use when applying the godot-resource-data-patterns capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-resource-data-patterns

This Builda skill adapts the upstream `godot-resource-data-patterns` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: data-release-role
- Canonical Builda owners: **resource-pattern**

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

- [`character_stats_resource.gd`](../scripts/gd-agentic-resource-data-patterns/character_stats_resource.gd)
- [`custom_data_resource.gd`](../scripts/gd-agentic-resource-data-patterns/custom_data_resource.gd)
- [`data_factory_resource.gd`](../scripts/gd-agentic-resource-data-patterns/data_factory_resource.gd)
- [`dynamic_resource_generation.gd`](../scripts/gd-agentic-resource-data-patterns/dynamic_resource_generation.gd)
- [`flyweight_enemy_config.gd`](../scripts/gd-agentic-resource-data-patterns/flyweight_enemy_config.gd)
- [`nested_resource_serialization.gd`](../scripts/gd-agentic-resource-data-patterns/nested_resource_serialization.gd)
- [`resource_based_inventory.gd`](../scripts/gd-agentic-resource-data-patterns/resource_based_inventory.gd)
- [`resource_flyweight_caching.gd`](../scripts/gd-agentic-resource-data-patterns/resource_flyweight_caching.gd)
- [`resource_local_to_scene.gd`](../scripts/gd-agentic-resource-data-patterns/resource_local_to_scene.gd)
- [`resource_pool.gd`](../scripts/gd-agentic-resource-data-patterns/resource_pool.gd)
- [`resource_preloading_strategy.gd`](../scripts/gd-agentic-resource-data-patterns/resource_preloading_strategy.gd)
- [`resource_save_system.gd`](../scripts/gd-agentic-resource-data-patterns/resource_save_system.gd)
- [`resource_validator.gd`](../scripts/gd-agentic-resource-data-patterns/resource_validator.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-turn-system
description: "Use when applying the godot-turn-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-turn-system

This Builda skill adapts the upstream `godot-turn-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **rule-resolution**

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

- [`active_time_battle.gd`](../scripts/gd-agentic-turn-system/active_time_battle.gd)
- [`combat_stats_resource.gd`](../scripts/gd-agentic-turn-system/combat_stats_resource.gd)
- [`timeline_turn_manager.gd`](../scripts/gd-agentic-turn-system/timeline_turn_manager.gd)
- [`turn_predictor.gd`](../scripts/gd-agentic-turn-system/turn_predictor.gd)
- [`turn_system_patterns.gd`](../scripts/gd-agentic-turn-system/turn_system_patterns.gd)

<!-- builda-script-index:end -->

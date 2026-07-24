---
name: gd-agentic-ability-system
description: "Use when applying the godot-ability-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-ability-system

This Builda skill adapts the upstream `godot-ability-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`ability_caster_network.gd`](../scripts/gd-agentic-ability-system/ability_caster_network.gd)
- [`ability_container.gd`](../scripts/gd-agentic-ability-system/ability_container.gd)
- [`ability_manager.gd`](../scripts/gd-agentic-ability-system/ability_manager.gd)
- [`ability_resource.gd`](../scripts/gd-agentic-ability-system/ability_resource.gd)
- [`buff_stat.gd`](../scripts/gd-agentic-ability-system/buff_stat.gd)
- [`charge_ability.gd`](../scripts/gd-agentic-ability-system/charge_ability.gd)
- [`combo_tracker.gd`](../scripts/gd-agentic-ability-system/combo_tracker.gd)
- [`skill_node.gd`](../scripts/gd-agentic-ability-system/skill_node.gd)
- [`skill_tree_manager.gd`](../scripts/gd-agentic-ability-system/skill_tree_manager.gd)
- [`status_effect.gd`](../scripts/gd-agentic-ability-system/status_effect.gd)
- [`status_effect_manager.gd`](../scripts/gd-agentic-ability-system/status_effect_manager.gd)

<!-- builda-script-index:end -->

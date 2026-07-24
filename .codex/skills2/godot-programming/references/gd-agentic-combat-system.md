---
name: gd-agentic-combat-system
description: "Use when applying the godot-combat-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-combat-system

This Builda skill adapts the upstream `godot-combat-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **combat-system**

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

- [`combat_logger.gd`](../scripts/gd-agentic-combat-system/combat_logger.gd)
- [`combat_state.gd`](../scripts/gd-agentic-combat-system/combat_state.gd)
- [`combat_system_patterns.gd`](../scripts/gd-agentic-combat-system/combat_system_patterns.gd)
- [`combo_system.gd`](../scripts/gd-agentic-combat-system/combo_system.gd)
- [`damage_data.gd`](../scripts/gd-agentic-combat-system/damage_data.gd)
- [`damage_popup.gd`](../scripts/gd-agentic-combat-system/damage_popup.gd)
- [`health_component.gd`](../scripts/gd-agentic-combat-system/health_component.gd)
- [`hitbox_component.gd`](../scripts/gd-agentic-combat-system/hitbox_component.gd)
- [`hitbox_hurtbox.gd`](../scripts/gd-agentic-combat-system/hitbox_hurtbox.gd)
- [`hitbox_visualizer.gd`](../scripts/gd-agentic-combat-system/hitbox_visualizer.gd)
- [`networked_damage_manager.gd`](../scripts/gd-agentic-combat-system/networked_damage_manager.gd)

<!-- builda-script-index:end -->

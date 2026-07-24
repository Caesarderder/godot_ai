---
name: gd-agentic-composition-apps
description: "Use when applying the godot-composition-apps capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-composition-apps

This Builda skill adapts the upstream `godot-composition-apps` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: ux-interface-role
- Canonical Builda owners: **ux-design**, **godot-ui**

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

- [`clipboard_copier.gd`](../scripts/gd-agentic-composition-apps/clipboard_copier.gd)
- [`comp_ability_sequencer.gd`](../scripts/gd-agentic-composition-apps/comp_ability_sequencer.gd)
- [`comp_base_component.gd`](../scripts/gd-agentic-composition-apps/comp_base_component.gd)
- [`comp_data_driven_config.gd`](../scripts/gd-agentic-composition-apps/comp_data_driven_config.gd)
- [`comp_dependency_injector.gd`](../scripts/gd-agentic-composition-apps/comp_dependency_injector.gd)
- [`comp_health_component.gd`](../scripts/gd-agentic-composition-apps/comp_health_component.gd)
- [`comp_hitbox_component.gd`](../scripts/gd-agentic-composition-apps/comp_hitbox_component.gd)
- [`comp_logic_visual_syncer.gd`](../scripts/gd-agentic-composition-apps/comp_logic_visual_syncer.gd)
- [`comp_orchestrator_base.gd`](../scripts/gd-agentic-composition-apps/comp_orchestrator_base.gd)
- [`comp_persistence_component.gd`](../scripts/gd-agentic-composition-apps/comp_persistence_component.gd)
- [`comp_rock_test_boilerplate.gd`](../scripts/gd-agentic-composition-apps/comp_rock_test_boilerplate.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-dialogue-system
description: "Use when applying the godot-dialogue-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-dialogue-system

This Builda skill adapts the upstream `godot-dialogue-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **narrative-runtime**

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

- [`branching_condition_validator.gd`](../scripts/gd-agentic-dialogue-system/branching_condition_validator.gd)
- [`dialogue_engine.gd`](../scripts/gd-agentic-dialogue-system/dialogue_engine.gd)
- [`dialogue_event_bridge.gd`](../scripts/gd-agentic-dialogue-system/dialogue_event_bridge.gd)
- [`dialogue_graph_editor.gd`](../scripts/gd-agentic-dialogue-system/dialogue_graph_editor.gd)
- [`dialogue_lipsync.gd`](../scripts/gd-agentic-dialogue-system/dialogue_lipsync.gd)
- [`dialogue_manager.gd`](../scripts/gd-agentic-dialogue-system/dialogue_manager.gd)
- [`dialogue_manager_singleton.gd`](../scripts/gd-agentic-dialogue-system/dialogue_manager_singleton.gd)
- [`dialogue_node_data.gd`](../scripts/gd-agentic-dialogue-system/dialogue_node_data.gd)
- [`dialogue_option_data.gd`](../scripts/gd-agentic-dialogue-system/dialogue_option_data.gd)
- [`dialogue_portrait_manager.gd`](../scripts/gd-agentic-dialogue-system/dialogue_portrait_manager.gd)
- [`dialogue_resource.gd`](../scripts/gd-agentic-dialogue-system/dialogue_resource.gd)
- [`dialogue_stat_logger.gd`](../scripts/gd-agentic-dialogue-system/dialogue_stat_logger.gd)
- [`dialogue_ui_controller.gd`](../scripts/gd-agentic-dialogue-system/dialogue_ui_controller.gd)
- [`localized_dialogue_resource.gd`](../scripts/gd-agentic-dialogue-system/localized_dialogue_resource.gd)
- [`typebox_effect.gd`](../scripts/gd-agentic-dialogue-system/typebox_effect.gd)

<!-- builda-script-index:end -->

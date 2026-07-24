---
name: gd-agentic-quest-system
description: "Use when applying the godot-quest-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-quest-system

This Builda skill adapts the upstream `godot-quest-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **objective-loop**

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

- [`branching_quest_data.gd`](../scripts/gd-agentic-quest-system/branching_quest_data.gd)
- [`hidden_objective_logic.gd`](../scripts/gd-agentic-quest-system/hidden_objective_logic.gd)
- [`kill_objective_trigger.gd`](../scripts/gd-agentic-quest-system/kill_objective_trigger.gd)
- [`localized_quest_description.gd`](../scripts/gd-agentic-quest-system/localized_quest_description.gd)
- [`quest_conflict_resolver.gd`](../scripts/gd-agentic-quest-system/quest_conflict_resolver.gd)
- [`quest_giver_dialogue_hook.gd`](../scripts/gd-agentic-quest-system/quest_giver_dialogue_hook.gd)
- [`quest_graph_manager.gd`](../scripts/gd-agentic-quest-system/quest_graph_manager.gd)
- [`quest_manager.gd`](../scripts/gd-agentic-quest-system/quest_manager.gd)
- [`quest_manager_singleton.gd`](../scripts/gd-agentic-quest-system/quest_manager_singleton.gd)
- [`quest_persistence_loader.gd`](../scripts/gd-agentic-quest-system/quest_persistence_loader.gd)
- [`quest_resource.gd`](../scripts/gd-agentic-quest-system/quest_resource.gd)
- [`quest_ui_tracker.gd`](../scripts/gd-agentic-quest-system/quest_ui_tracker.gd)
- [`quest_waypoint_helper.gd`](../scripts/gd-agentic-quest-system/quest_waypoint_helper.gd)
- [`timed_quest_challenge.gd`](../scripts/gd-agentic-quest-system/timed_quest_challenge.gd)

<!-- builda-script-index:end -->

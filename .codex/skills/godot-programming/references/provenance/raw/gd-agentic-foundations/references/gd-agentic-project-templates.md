---
name: gd-agentic-project-templates
description: "Use when applying the godot-project-templates capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-project-templates

This Builda skill adapts the upstream `godot-project-templates` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-programming-role
- Canonical Builda owners: **game-technical-design**, **godot-code-review**

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

- [`accessibility_tts_manager.gd`](../scripts/gd-agentic-project-templates/accessibility_tts_manager.gd)
- [`base_actor.gd`](../scripts/gd-agentic-project-templates/base_actor.gd)
- [`base_game_manager.gd`](../scripts/gd-agentic-project-templates/base_game_manager.gd)
- [`base_level.gd`](../scripts/gd-agentic-project-templates/base_level.gd)
- [`base_menu.gd`](../scripts/gd-agentic-project-templates/base_menu.gd)
- [`bootstrap_config.gd`](../scripts/gd-agentic-project-templates/bootstrap_config.gd)
- [`level_steamer_manager.gd`](../scripts/gd-agentic-project-templates/level_steamer_manager.gd)
- [`modular_dlc_loader.gd`](../scripts/gd-agentic-project-templates/modular_dlc_loader.gd)
- [`multi_platform_input.gd`](../scripts/gd-agentic-project-templates/multi_platform_input.gd)
- [`platform_feature_config.gd`](../scripts/gd-agentic-project-templates/platform_feature_config.gd)
- [`scene_state_machine.gd`](../scripts/gd-agentic-project-templates/scene_state_machine.gd)
- [`state_machine_node.gd`](../scripts/gd-agentic-project-templates/state_machine_node.gd)
- [`subsystem_locator.gd`](../scripts/gd-agentic-project-templates/subsystem_locator.gd)

<!-- builda-script-index:end -->

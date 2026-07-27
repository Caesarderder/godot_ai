---
name: gd-agentic-genre-romance
description: "Use when applying the godot-genre-romance capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-romance

This Builda skill adapts the upstream `godot-genre-romance` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`affection_manager.gd`](../scripts/gd-agentic-genre-romance/affection_manager.gd)
- [`date_event_system.gd`](../scripts/gd-agentic-genre-romance/date_event_system.gd)
- [`dialogue_expression_parser.gd`](../scripts/gd-agentic-genre-romance/dialogue_expression_parser.gd)
- [`global_affection_tracker.gd`](../scripts/gd-agentic-genre-romance/global_affection_tracker.gd)
- [`npc_schedule.gd`](../scripts/gd-agentic-genre-romance/npc_schedule.gd)
- [`player_romance_manager.gd`](../scripts/gd-agentic-genre-romance/player_romance_manager.gd)
- [`romance_mood_manager.gd`](../scripts/gd-agentic-genre-romance/romance_mood_manager.gd)
- [`romance_patterns.gd`](../scripts/gd-agentic-genre-romance/romance_patterns.gd)
- [`route_manager.gd`](../scripts/gd-agentic-genre-romance/route_manager.gd)
- [`seasonal_dialogue.gd`](../scripts/gd-agentic-genre-romance/seasonal_dialogue.gd)
- [`ui_feedback.gd`](../scripts/gd-agentic-genre-romance/ui_feedback.gd)

<!-- builda-script-index:end -->

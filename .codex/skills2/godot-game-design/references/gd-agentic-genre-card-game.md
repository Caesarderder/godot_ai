---
name: gd-agentic-genre-card-game
description: "Use when applying the godot-genre-card-game capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-card-game

This Builda skill adapts the upstream `godot-genre-card-game` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`board_query_filter.gd`](../scripts/gd-agentic-genre-card-game/board_query_filter.gd)
- [`board_state_dictionary.gd`](../scripts/gd-agentic-genre-card-game/board_state_dictionary.gd)
- [`card_data.gd`](../scripts/gd-agentic-genre-card-game/card_data.gd)
- [`card_data_resource.gd`](../scripts/gd-agentic-genre-card-game/card_data_resource.gd)
- [`card_drag_drop.gd`](../scripts/gd-agentic-genre-card-game/card_drag_drop.gd)
- [`card_effect_resolution.gd`](../scripts/gd-agentic-genre-card-game/card_effect_resolution.gd)
- [`card_history_logger.gd`](../scripts/gd-agentic-genre-card-game/card_history_logger.gd)
- [`card_tween_manager.gd`](../scripts/gd-agentic-genre-card-game/card_tween_manager.gd)
- [`deck_builder_validator.gd`](../scripts/gd-agentic-genre-card-game/deck_builder_validator.gd)
- [`deck_shuffle_bag.gd`](../scripts/gd-agentic-genre-card-game/deck_shuffle_bag.gd)
- [`hand_manager.gd`](../scripts/gd-agentic-genre-card-game/hand_manager.gd)
- [`match_state_resetter.gd`](../scripts/gd-agentic-genre-card-game/match_state_resetter.gd)
- [`reactive_card_ui.gd`](../scripts/gd-agentic-genre-card-game/reactive_card_ui.gd)
- [`turn_state_machine.gd`](../scripts/gd-agentic-genre-card-game/turn_state_machine.gd)

<!-- builda-script-index:end -->

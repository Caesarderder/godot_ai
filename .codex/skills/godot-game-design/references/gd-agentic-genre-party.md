---
name: gd-agentic-genre-party
description: "Use when applying the godot-genre-party capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-party

This Builda skill adapts the upstream `godot-genre-party` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`character_select_grid.gd`](../scripts/gd-agentic-genre-party/character_select_grid.gd)
- [`connection_monitor.gd`](../scripts/gd-agentic-genre-party/connection_monitor.gd)
- [`deferred_scene_switcher.gd`](../scripts/gd-agentic-genre-party/deferred_scene_switcher.gd)
- [`impact_camera_shake.gd`](../scripts/gd-agentic-genre-party/impact_camera_shake.gd)
- [`local_input_manager.gd`](../scripts/gd-agentic-genre-party/local_input_manager.gd)
- [`minigame_async_loader.gd`](../scripts/gd-agentic-genre-party/minigame_async_loader.gd)
- [`minigame_data.gd`](../scripts/gd-agentic-genre-party/minigame_data.gd)
- [`minigame_orchestrator.gd`](../scripts/gd-agentic-genre-party/minigame_orchestrator.gd)
- [`minigame_player_controller.gd`](../scripts/gd-agentic-genre-party/minigame_player_controller.gd)
- [`party_input_router.gd`](../scripts/gd-agentic-genre-party/party_input_router.gd)
- [`party_manager.gd`](../scripts/gd-agentic-genre-party/party_manager.gd)
- [`player_haptic_feedback.gd`](../scripts/gd-agentic-genre-party/player_haptic_feedback.gd)
- [`player_join_manager.gd`](../scripts/gd-agentic-genre-party/player_join_manager.gd)
- [`shared_party_camera.gd`](../scripts/gd-agentic-genre-party/shared_party_camera.gd)
- [`split_screen_manager.gd`](../scripts/gd-agentic-genre-party/split_screen_manager.gd)
- [`split_screen_setup.gd`](../scripts/gd-agentic-genre-party/split_screen_setup.gd)
- [`tournament_state.gd`](../scripts/gd-agentic-genre-party/tournament_state.gd)

<!-- builda-script-index:end -->

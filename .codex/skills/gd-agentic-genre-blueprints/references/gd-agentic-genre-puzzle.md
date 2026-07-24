---
name: gd-agentic-genre-puzzle
description: "Use when applying the godot-genre-puzzle capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-puzzle

This Builda skill adapts the upstream `godot-genre-puzzle` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`command_undo_redo.gd`](../scripts/gd-agentic-genre-puzzle/command_undo_redo.gd)
- [`grid_input_manager.gd`](../scripts/gd-agentic-genre-puzzle/grid_input_manager.gd)
- [`grid_manager.gd`](../scripts/gd-agentic-genre-puzzle/grid_manager.gd)
- [`grid_tween_mover.gd`](../scripts/gd-agentic-genre-puzzle/grid_tween_mover.gd)
- [`match_three_logic.gd`](../scripts/gd-agentic-genre-puzzle/match_three_logic.gd)
- [`perspective_overlay.gd`](../scripts/gd-agentic-genre-puzzle/perspective_overlay.gd)
- [`puzzle_history.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_history.gd)
- [`puzzle_pathfinder.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_pathfinder.gd)
- [`puzzle_saver.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_saver.gd)
- [`puzzle_state_validator.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_state_validator.gd)
- [`puzzle_undo_manager.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_undo_manager.gd)
- [`puzzle_validator.gd`](../scripts/gd-agentic-genre-puzzle/puzzle_validator.gd)
- [`shuffle_bag.gd`](../scripts/gd-agentic-genre-puzzle/shuffle_bag.gd)
- [`sleepy_block.gd`](../scripts/gd-agentic-genre-puzzle/sleepy_block.gd)
- [`tile_animator.gd`](../scripts/gd-agentic-genre-puzzle/tile_animator.gd)

<!-- builda-script-index:end -->

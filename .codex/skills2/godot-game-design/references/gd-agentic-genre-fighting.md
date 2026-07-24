---
name: gd-agentic-genre-fighting
description: "Use when applying the godot-genre-fighting capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-fighting

This Builda skill adapts the upstream `godot-genre-fighting` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`attack_resource.gd`](../scripts/gd-agentic-genre-fighting/attack_resource.gd)
- [`bitwise_state_flags.gd`](../scripts/gd-agentic-genre-fighting/bitwise_state_flags.gd)
- [`combo_tracker.gd`](../scripts/gd-agentic-genre-fighting/combo_tracker.gd)
- [`deterministic_physics_loop.gd`](../scripts/gd-agentic-genre-fighting/deterministic_physics_loop.gd)
- [`direct_hitbox_query.gd`](../scripts/gd-agentic-genre-fighting/direct_hitbox_query.gd)
- [`fight_game_state.gd`](../scripts/gd-agentic-genre-fighting/fight_game_state.gd)
- [`fighter_balance_profile.gd`](../scripts/gd-agentic-genre-fighting/fighter_balance_profile.gd)
- [`fighter_state_machine.gd`](../scripts/gd-agentic-genre-fighting/fighter_state_machine.gd)
- [`fighting_input_buffer.gd`](../scripts/gd-agentic-genre-fighting/fighting_input_buffer.gd)
- [`frame_advancer.gd`](../scripts/gd-agentic-genre-fighting/frame_advancer.gd)
- [`hit_stop_controller.gd`](../scripts/gd-agentic-genre-fighting/hit_stop_controller.gd)
- [`hitbox_component.gd`](../scripts/gd-agentic-genre-fighting/hitbox_component.gd)
- [`input_accumulation_control.gd`](../scripts/gd-agentic-genre-fighting/input_accumulation_control.gd)
- [`manual_animation_advancer.gd`](../scripts/gd-agentic-genre-fighting/manual_animation_advancer.gd)
- [`move_set_loader.gd`](../scripts/gd-agentic-genre-fighting/move_set_loader.gd)
- [`raw_byte_network_sync.gd`](../scripts/gd-agentic-genre-fighting/raw_byte_network_sync.gd)
- [`rollback_state_serializer.gd`](../scripts/gd-agentic-genre-fighting/rollback_state_serializer.gd)
- [`round_timer_logic.gd`](../scripts/gd-agentic-genre-fighting/round_timer_logic.gd)
- [`string_name_optimization.gd`](../scripts/gd-agentic-genre-fighting/string_name_optimization.gd)

<!-- builda-script-index:end -->

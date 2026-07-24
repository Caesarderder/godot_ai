---
name: gd-agentic-genre-shooter-fps
description: "Use when applying the godot-genre-shooter-fps capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-shooter-fps

This Builda skill adapts the upstream `godot-genre-shooter-fps` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`advanced_fps_controller.gd`](../scripts/gd-agentic-genre-shooter-fps/advanced_fps_controller.gd)
- [`advanced_weapon_controller.gd`](../scripts/gd-agentic-genre-shooter-fps/advanced_weapon_controller.gd)
- [`aim_assist.gd`](../scripts/gd-agentic-genre-shooter-fps/aim_assist.gd)
- [`bullet_decal_spawner.gd`](../scripts/gd-agentic-genre-shooter-fps/bullet_decal_spawner.gd)
- [`fps_camera_look.gd`](../scripts/gd-agentic-genre-shooter-fps/fps_camera_look.gd)
- [`fps_movement_logic.gd`](../scripts/gd-agentic-genre-shooter-fps/fps_movement_logic.gd)
- [`frame_perfect_input.gd`](../scripts/gd-agentic-genre-shooter-fps/frame_perfect_input.gd)
- [`hitscan_weapon_logic.gd`](../scripts/gd-agentic-genre-shooter-fps/hitscan_weapon_logic.gd)
- [`hitscan_weapon_query.gd`](../scripts/gd-agentic-genre-shooter-fps/hitscan_weapon_query.gd)
- [`player_anim_bridge.gd`](../scripts/gd-agentic-genre-shooter-fps/player_anim_bridge.gd)
- [`procedural_recoil_handler.gd`](../scripts/gd-agentic-genre-shooter-fps/procedural_recoil_handler.gd)
- [`recoil_system.gd`](../scripts/gd-agentic-genre-shooter-fps/recoil_system.gd)
- [`server_projectile_instance.gd`](../scripts/gd-agentic-genre-shooter-fps/server_projectile_instance.gd)
- [`weapon_bobbing_system.gd`](../scripts/gd-agentic-genre-shooter-fps/weapon_bobbing_system.gd)
- [`weapon_spread_calc.gd`](../scripts/gd-agentic-genre-shooter-fps/weapon_spread_calc.gd)
- [`weapon_state_machine.gd`](../scripts/gd-agentic-genre-shooter-fps/weapon_state_machine.gd)

<!-- builda-script-index:end -->

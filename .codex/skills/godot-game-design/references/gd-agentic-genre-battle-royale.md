---
name: gd-agentic-genre-battle-royale
description: "Use when applying the godot-genre-battle-royale capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-battle-royale

This Builda skill adapts the upstream `godot-genre-battle-royale` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`async_map_loader.gd`](../scripts/gd-agentic-genre-battle-royale/async_map_loader.gd)
- [`authoritative_looting.gd`](../scripts/gd-agentic-genre-battle-royale/authoritative_looting.gd)
- [`enet_br_server.gd`](../scripts/gd-agentic-genre-battle-royale/enet_br_server.gd)
- [`headless_branch_logic.gd`](../scripts/gd-agentic-genre-battle-royale/headless_branch_logic.gd)
- [`kill_feed_bus.gd`](../scripts/gd-agentic-genre-battle-royale/kill_feed_bus.gd)
- [`lag_compensator.gd`](../scripts/gd-agentic-genre-battle-royale/lag_compensator.gd)
- [`monster_synchronizer.gd`](../scripts/gd-agentic-genre-battle-royale/monster_synchronizer.gd)
- [`multimesh_vegetation.gd`](../scripts/gd-agentic-genre-battle-royale/multimesh_vegetation.gd)
- [`rid_loot_spawner.gd`](../scripts/gd-agentic-genre-battle-royale/rid_loot_spawner.gd)
- [`server_state_buffer.gd`](../scripts/gd-agentic-genre-battle-royale/server_state_buffer.gd)
- [`state_replication_unreliable.gd`](../scripts/gd-agentic-genre-battle-royale/state_replication_unreliable.gd)
- [`storm_system.gd`](../scripts/gd-agentic-genre-battle-royale/storm_system.gd)
- [`targeted_rpc_relay.gd`](../scripts/gd-agentic-genre-battle-royale/targeted_rpc_relay.gd)
- [`threaded_ai_manager.gd`](../scripts/gd-agentic-genre-battle-royale/threaded_ai_manager.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-genre-simulation
description: "Use when applying the godot-genre-simulation capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-simulation

This Builda skill adapts the upstream `godot-genre-simulation` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`customer_simulation.gd`](../scripts/gd-agentic-genre-simulation/customer_simulation.gd)
- [`economy_graph_manager.gd`](../scripts/gd-agentic-genre-simulation/economy_graph_manager.gd)
- [`facility.gd`](../scripts/gd-agentic-genre-simulation/facility.gd)
- [`npc_schedule_agent.gd`](../scripts/gd-agentic-genre-simulation/npc_schedule_agent.gd)
- [`resource_flow_visualizer.gd`](../scripts/gd-agentic-genre-simulation/resource_flow_visualizer.gd)
- [`sim_tick_manager.gd`](../scripts/gd-agentic-genre-simulation/sim_tick_manager.gd)
- [`simulation_patterns.gd`](../scripts/gd-agentic-genre-simulation/simulation_patterns.gd)
- [`simulation_tick_controller.gd`](../scripts/gd-agentic-genre-simulation/simulation_tick_controller.gd)
- [`stats_dashboard.gd`](../scripts/gd-agentic-genre-simulation/stats_dashboard.gd)
- [`tycoon_economy.gd`](../scripts/gd-agentic-genre-simulation/tycoon_economy.gd)
- [`unlock_system.gd`](../scripts/gd-agentic-genre-simulation/unlock_system.gd)
- [`worker.gd`](../scripts/gd-agentic-genre-simulation/worker.gd)

<!-- builda-script-index:end -->

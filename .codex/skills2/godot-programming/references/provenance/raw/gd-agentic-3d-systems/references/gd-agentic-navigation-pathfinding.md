---
name: gd-agentic-navigation-pathfinding
description: "Use when applying the godot-navigation-pathfinding capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-navigation-pathfinding

This Builda skill adapts the upstream `godot-navigation-pathfinding` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **ai-navigation**

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

- [`agent_stuck_detection.gd`](../scripts/gd-agentic-navigation-pathfinding/agent_stuck_detection.gd)
- [`async_dynamic_baking.gd`](../scripts/gd-agentic-navigation-pathfinding/async_dynamic_baking.gd)
- [`crowd_agent_3d.gd`](../scripts/gd-agentic-navigation-pathfinding/crowd_agent_3d.gd)
- [`dynamic_nav_manager.gd`](../scripts/gd-agentic-navigation-pathfinding/dynamic_nav_manager.gd)
- [`group_avoidance_formations.gd`](../scripts/gd-agentic-navigation-pathfinding/group_avoidance_formations.gd)
- [`layer_mask_navigation.gd`](../scripts/gd-agentic-navigation-pathfinding/layer_mask_navigation.gd)
- [`low_level_avoidance.gd`](../scripts/gd-agentic-navigation-pathfinding/low_level_avoidance.gd)
- [`memory_optimized_queries.gd`](../scripts/gd-agentic-navigation-pathfinding/memory_optimized_queries.gd)
- [`moving_obstacle_server.gd`](../scripts/gd-agentic-navigation-pathfinding/moving_obstacle_server.gd)
- [`nav_link_traversal.gd`](../scripts/gd-agentic-navigation-pathfinding/nav_link_traversal.gd)
- [`nav_mesh_carver_3d.gd`](../scripts/gd-agentic-navigation-pathfinding/nav_mesh_carver_3d.gd)
- [`navmesh_profiler.gd`](../scripts/gd-agentic-navigation-pathfinding/navmesh_profiler.gd)
- [`server_navigation_setup.gd`](../scripts/gd-agentic-navigation-pathfinding/server_navigation_setup.gd)
- [`smart_navigation_agent.gd`](../scripts/gd-agentic-navigation-pathfinding/smart_navigation_agent.gd)
- [`terrain_cost_manager.gd`](../scripts/gd-agentic-navigation-pathfinding/terrain_cost_manager.gd)

<!-- builda-script-index:end -->

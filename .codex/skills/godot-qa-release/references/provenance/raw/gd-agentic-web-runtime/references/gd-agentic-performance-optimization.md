---
name: gd-agentic-performance-optimization
description: "Use when applying the godot-performance-optimization capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-performance-optimization

This Builda skill adapts the upstream `godot-performance-optimization` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: data-release-role
- Canonical Builda owners: **godot-optimization**

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

- [`custom_monitor_profiler.gd`](../scripts/gd-agentic-performance-optimization/custom_monitor_profiler.gd)
- [`custom_performance_monitor.gd`](../scripts/gd-agentic-performance-optimization/custom_performance_monitor.gd)
- [`low_level_physics_query.gd`](../scripts/gd-agentic-performance-optimization/low_level_physics_query.gd)
- [`manual_culling_logic.gd`](../scripts/gd-agentic-performance-optimization/manual_culling_logic.gd)
- [`multimesh_foliage_manager.gd`](../scripts/gd-agentic-performance-optimization/multimesh_foliage_manager.gd)
- [`multimesh_optimizer.gd`](../scripts/gd-agentic-performance-optimization/multimesh_optimizer.gd)
- [`navigation_agent_optimization.gd`](../scripts/gd-agentic-performance-optimization/navigation_agent_optimization.gd)
- [`object_pool_system.gd`](../scripts/gd-agentic-performance-optimization/object_pool_system.gd)
- [`rendering_server_direct.gd`](../scripts/gd-agentic-performance-optimization/rendering_server_direct.gd)
- [`shared_resource_strategy.gd`](../scripts/gd-agentic-performance-optimization/shared_resource_strategy.gd)
- [`texture_array_batching.gd`](../scripts/gd-agentic-performance-optimization/texture_array_batching.gd)
- [`worker_thread_pool_manager.gd`](../scripts/gd-agentic-performance-optimization/worker_thread_pool_manager.gd)

<!-- builda-script-index:end -->

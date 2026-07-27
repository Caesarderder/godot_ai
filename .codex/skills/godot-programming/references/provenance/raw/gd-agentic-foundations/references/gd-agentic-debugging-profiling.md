---
name: gd-agentic-debugging-profiling
description: "Use when applying the godot-debugging-profiling capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-debugging-profiling

This Builda skill adapts the upstream `godot-debugging-profiling` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-programming-role
- Canonical Builda owners: **game-technical-design**, **godot-code-review**

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

- [`advanced_backtrace_recorder.gd`](../scripts/gd-agentic-debugging-profiling/advanced_backtrace_recorder.gd)
- [`automated_qa_suite.gd`](../scripts/gd-agentic-debugging-profiling/automated_qa_suite.gd)
- [`break_on_condition.gd`](../scripts/gd-agentic-debugging-profiling/break_on_condition.gd)
- [`custom_debug_draw.gd`](../scripts/gd-agentic-debugging-profiling/custom_debug_draw.gd)
- [`custom_editor_monitor.gd`](../scripts/gd-agentic-debugging-profiling/custom_editor_monitor.gd)
- [`debug_overlay.gd`](../scripts/gd-agentic-debugging-profiling/debug_overlay.gd)
- [`debugger_tab_plugin.gd`](../scripts/gd-agentic-debugging-profiling/debugger_tab_plugin.gd)
- [`engine_editor_hint_logic.gd`](../scripts/gd-agentic-debugging-profiling/engine_editor_hint_logic.gd)
- [`engine_error_interceptor.gd`](../scripts/gd-agentic-debugging-profiling/engine_error_interceptor.gd)
- [`high_precision_benchmarker.gd`](../scripts/gd-agentic-debugging-profiling/high_precision_benchmarker.gd)
- [`memory_usage_threshold_alert.gd`](../scripts/gd-agentic-debugging-profiling/memory_usage_threshold_alert.gd)
- [`orphan_node_detector.gd`](../scripts/gd-agentic-debugging-profiling/orphan_node_detector.gd)
- [`performance_plotter.gd`](../scripts/gd-agentic-debugging-profiling/performance_plotter.gd)
- [`property_watcher_gizmo.gd`](../scripts/gd-agentic-debugging-profiling/property_watcher_gizmo.gd)
- [`push_error_safe_exit.gd`](../scripts/gd-agentic-debugging-profiling/push_error_safe_exit.gd)
- [`remote_debug_console.gd`](../scripts/gd-agentic-debugging-profiling/remote_debug_console.gd)
- [`scene_tree_dump.gd`](../scripts/gd-agentic-debugging-profiling/scene_tree_dump.gd)
- [`stack_trace_logger.gd`](../scripts/gd-agentic-debugging-profiling/stack_trace_logger.gd)
- [`thread_safe_logger.gd`](../scripts/gd-agentic-debugging-profiling/thread_safe_logger.gd)
- [`thread_safety_assert.gd`](../scripts/gd-agentic-debugging-profiling/thread_safety_assert.gd)

<!-- builda-script-index:end -->

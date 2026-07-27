---
name: gd-agentic-autoload-architecture
description: "Use when applying the godot-autoload-architecture capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-autoload-architecture

This Builda skill adapts the upstream `godot-autoload-architecture` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`autoload_bootstrapper.gd`](../scripts/gd-agentic-autoload-architecture/autoload_bootstrapper.gd)
- [`autoload_init_order_diag.gd`](../scripts/gd-agentic-autoload-architecture/autoload_init_order_diag.gd)
- [`autoload_initializer.gd`](../scripts/gd-agentic-autoload-architecture/autoload_initializer.gd)
- [`autoload_reference_checker.gd`](../scripts/gd-agentic-autoload-architecture/autoload_reference_checker.gd)
- [`cross_autoload_comms.gd`](../scripts/gd-agentic-autoload-architecture/cross_autoload_comms.gd)
- [`debug_console_autoload.gd`](../scripts/gd-agentic-autoload-architecture/debug_console_autoload.gd)
- [`global_event_bus.gd`](../scripts/gd-agentic-autoload-architecture/global_event_bus.gd)
- [`global_game_state.gd`](../scripts/gd-agentic-autoload-architecture/global_game_state.gd)
- [`lazy_loaded_singleton.gd`](../scripts/gd-agentic-autoload-architecture/lazy_loaded_singleton.gd)
- [`persistent_data_holder.gd`](../scripts/gd-agentic-autoload-architecture/persistent_data_holder.gd)
- [`safe_scene_switcher.gd`](../scripts/gd-agentic-autoload-architecture/safe_scene_switcher.gd)
- [`service_locator.gd`](../scripts/gd-agentic-autoload-architecture/service_locator.gd)
- [`service_registry.gd`](../scripts/gd-agentic-autoload-architecture/service_registry.gd)
- [`singleton_dependency_diagram.gd`](../scripts/gd-agentic-autoload-architecture/singleton_dependency_diagram.gd)
- [`singleton_health_check_test.gd`](../scripts/gd-agentic-autoload-architecture/singleton_health_check_test.gd)
- [`stateless_bus.gd`](../scripts/gd-agentic-autoload-architecture/stateless_bus.gd)
- [`static_state_manager.gd`](../scripts/gd-agentic-autoload-architecture/static_state_manager.gd)
- [`thread_safe_global_access.gd`](../scripts/gd-agentic-autoload-architecture/thread_safe_global_access.gd)

<!-- builda-script-index:end -->

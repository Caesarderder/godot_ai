---
name: gd-agentic-project-foundations
description: "Use when applying the godot-project-foundations capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-project-foundations

This Builda skill adapts the upstream `godot-project-foundations` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`action_buffer_input.gd`](../scripts/gd-agentic-project-foundations/action_buffer_input.gd)
- [`advanced_telemetry_logger.gd`](../scripts/gd-agentic-project-foundations/advanced_telemetry_logger.gd)
- [`async_resource_loader.gd`](../scripts/gd-agentic-project-foundations/async_resource_loader.gd)
- [`base_data_resource.gd`](../scripts/gd-agentic-project-foundations/base_data_resource.gd)
- [`build_metadata_provider.gd`](../scripts/gd-agentic-project-foundations/build_metadata_provider.gd)
- [`dependency_auditor.gd`](../scripts/gd-agentic-project-foundations/dependency_auditor.gd)
- [`feature_scaffolder.gd`](../scripts/gd-agentic-project-foundations/feature_scaffolder.gd)
- [`global_event_bus.gd`](../scripts/gd-agentic-project-foundations/global_event_bus.gd)
- [`managed_autoload.gd`](../scripts/gd-agentic-project-foundations/managed_autoload.gd)
- [`node_pooling_system.gd`](../scripts/gd-agentic-project-foundations/node_pooling_system.gd)
- [`project_bootstrapper.gd`](../scripts/gd-agentic-project-foundations/project_bootstrapper.gd)
- [`runtime_configurator.gd`](../scripts/gd-agentic-project-foundations/runtime_configurator.gd)
- [`scene_naming_validator.gd`](../scripts/gd-agentic-project-foundations/scene_naming_validator.gd)
- [`threaded_task_worker.gd`](../scripts/gd-agentic-project-foundations/threaded_task_worker.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-testing-patterns
description: "Use when applying the godot-testing-patterns capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-testing-patterns

This Builda skill adapts the upstream `godot-testing-patterns` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`basic_unit_test.gd`](../scripts/gd-agentic-testing-patterns/basic_unit_test.gd)
- [`headless_test_runner.gd`](../scripts/gd-agentic-testing-patterns/headless_test_runner.gd)
- [`integration_test_base.gd`](../scripts/gd-agentic-testing-patterns/integration_test_base.gd)
- [`memory_leak_detector.gd`](../scripts/gd-agentic-testing-patterns/memory_leak_detector.gd)
- [`mock_dependency_test.gd`](../scripts/gd-agentic-testing-patterns/mock_dependency_test.gd)
- [`mock_network_provider.gd`](../scripts/gd-agentic-testing-patterns/mock_network_provider.gd)
- [`parameter_fuzz_tester.gd`](../scripts/gd-agentic-testing-patterns/parameter_fuzz_tester.gd)
- [`performance_benchmark_runner.gd`](../scripts/gd-agentic-testing-patterns/performance_benchmark_runner.gd)
- [`physics_collision_test.gd`](../scripts/gd-agentic-testing-patterns/physics_collision_test.gd)
- [`scene_integration_test.gd`](../scripts/gd-agentic-testing-patterns/scene_integration_test.gd)
- [`signal_emission_test.gd`](../scripts/gd-agentic-testing-patterns/signal_emission_test.gd)
- [`snapshot_tester.gd`](../scripts/gd-agentic-testing-patterns/snapshot_tester.gd)
- [`test_data_factory.gd`](../scripts/gd-agentic-testing-patterns/test_data_factory.gd)
- [`wait_for_frame_test.gd`](../scripts/gd-agentic-testing-patterns/wait_for_frame_test.gd)

<!-- builda-script-index:end -->

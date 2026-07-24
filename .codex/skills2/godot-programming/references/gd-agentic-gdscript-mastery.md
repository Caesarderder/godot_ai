---
name: gd-agentic-gdscript-mastery
description: "Use when applying the godot-gdscript-mastery capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-gdscript-mastery

This Builda skill adapts the upstream `godot-gdscript-mastery` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`advanced_lambdas.gd`](../scripts/gd-agentic-gdscript-mastery/advanced_lambdas.gd)
- [`array_preallocation_perf.gd`](../scripts/gd-agentic-gdscript-mastery/array_preallocation_perf.gd)
- [`await_sequence_manager.gd`](../scripts/gd-agentic-gdscript-mastery/await_sequence_manager.gd)
- [`callable_binding_context.gd`](../scripts/gd-agentic-gdscript-mastery/callable_binding_context.gd)
- [`dictionary_safe_iteration.gd`](../scripts/gd-agentic-gdscript-mastery/dictionary_safe_iteration.gd)
- [`functional_lambda_logic.gd`](../scripts/gd-agentic-gdscript-mastery/functional_lambda_logic.gd)
- [`performance_analyzer.gd`](../scripts/gd-agentic-gdscript-mastery/performance_analyzer.gd)
- [`safe_type_casting.gd`](../scripts/gd-agentic-gdscript-mastery/safe_type_casting.gd)
- [`signal_architecture_validator.gd`](../scripts/gd-agentic-gdscript-mastery/signal_architecture_validator.gd)
- [`static_var_singleton_alt.gd`](../scripts/gd-agentic-gdscript-mastery/static_var_singleton_alt.gd)
- [`type_checker.gd`](../scripts/gd-agentic-gdscript-mastery/type_checker.gd)
- [`typed_collections_mastery.gd`](../scripts/gd-agentic-gdscript-mastery/typed_collections_mastery.gd)
- [`typed_signal_definitions.gd`](../scripts/gd-agentic-gdscript-mastery/typed_signal_definitions.gd)
- [`unbind_signal_args.gd`](../scripts/gd-agentic-gdscript-mastery/unbind_signal_args.gd)

<!-- builda-script-index:end -->

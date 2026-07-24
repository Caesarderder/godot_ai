---
name: gd-agentic-signal-architecture
description: "Use when applying the godot-signal-architecture capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-signal-architecture

This Builda skill adapts the upstream `godot-signal-architecture` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`await_signal_sequencing.gd`](../scripts/gd-agentic-signal-architecture/await_signal_sequencing.gd)
- [`callable_bind_context.gd`](../scripts/gd-agentic-signal-architecture/callable_bind_context.gd)
- [`complex_signal_sequencer.gd`](../scripts/gd-agentic-signal-architecture/complex_signal_sequencer.gd)
- [`disconnect_ghost_signals.gd`](../scripts/gd-agentic-signal-architecture/disconnect_ghost_signals.gd)
- [`global_event_bus.gd`](../scripts/gd-agentic-signal-architecture/global_event_bus.gd)
- [`global_signal_bus_router.gd`](../scripts/gd-agentic-signal-architecture/global_signal_bus_router.gd)
- [`one_shot_deferred_connections.gd`](../scripts/gd-agentic-signal-architecture/one_shot_deferred_connections.gd)
- [`safe_dynamic_connections.gd`](../scripts/gd-agentic-signal-architecture/safe_dynamic_connections.gd)
- [`signal_debugger.gd`](../scripts/gd-agentic-signal-architecture/signal_debugger.gd)
- [`signal_spy.gd`](../scripts/gd-agentic-signal-architecture/signal_spy.gd)
- [`signal_up_call_down_pattern.gd`](../scripts/gd-agentic-signal-architecture/signal_up_call_down_pattern.gd)
- [`track_signal_emitter_source.gd`](../scripts/gd-agentic-signal-architecture/track_signal_emitter_source.gd)
- [`unbind_unwanted_args.gd`](../scripts/gd-agentic-signal-architecture/unbind_unwanted_args.gd)

<!-- builda-script-index:end -->

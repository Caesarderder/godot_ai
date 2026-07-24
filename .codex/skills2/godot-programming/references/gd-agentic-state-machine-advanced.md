---
name: gd-agentic-state-machine-advanced
description: "Use when applying the godot-state-machine-advanced capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-state-machine-advanced

This Builda skill adapts the upstream `godot-state-machine-advanced` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **state-machine**

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

- [`hsm_animation_syncer.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_animation_syncer.gd)
- [`hsm_concurrent_logic.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_concurrent_logic.gd)
- [`hsm_hierarchical_base.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_hierarchical_base.gd)
- [`hsm_logic_state.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_logic_state.gd)
- [`hsm_pushdown_stack.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_pushdown_stack.gd)
- [`hsm_reentry_aware_state.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_reentry_aware_state.gd)
- [`hsm_resource_state_loader.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_resource_state_loader.gd)
- [`hsm_state_context.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_state_context.gd)
- [`hsm_state_history_logger.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_state_history_logger.gd)
- [`hsm_state_timer_component.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_state_timer_component.gd)
- [`hsm_transition_guard.gd`](../scripts/gd-agentic-state-machine-advanced/hsm_transition_guard.gd)
- [`pushdown_automaton.gd`](../scripts/gd-agentic-state-machine-advanced/pushdown_automaton.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-input-handling
description: "Use when applying the godot-input-handling capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-input-handling

This Builda skill adapts the upstream `godot-input-handling` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **input-handling**

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

- [`action_state_machine.gd`](../scripts/gd-agentic-input-handling/action_state_machine.gd)
- [`advanced_input_buffer.gd`](../scripts/gd-agentic-input-handling/advanced_input_buffer.gd)
- [`analog_deadzone_manager.gd`](../scripts/gd-agentic-input-handling/analog_deadzone_manager.gd)
- [`combo_validator.gd`](../scripts/gd-agentic-input-handling/combo_validator.gd)
- [`glyph_prompt_manager.gd`](../scripts/gd-agentic-input-handling/glyph_prompt_manager.gd)
- [`hold_toggle_accessibility.gd`](../scripts/gd-agentic-input-handling/hold_toggle_accessibility.gd)
- [`input_buffer.gd`](../scripts/gd-agentic-input-handling/input_buffer.gd)
- [`input_buffer_manager.gd`](../scripts/gd-agentic-input-handling/input_buffer_manager.gd)
- [`input_echo_filter.gd`](../scripts/gd-agentic-input-handling/input_echo_filter.gd)
- [`input_remapper.gd`](../scripts/gd-agentic-input-handling/input_remapper.gd)
- [`input_replay_buffer.gd`](../scripts/gd-agentic-input-handling/input_replay_buffer.gd)
- [`mouse_capture_manager.gd`](../scripts/gd-agentic-input-handling/mouse_capture_manager.gd)
- [`multi_touch_gestures.gd`](../scripts/gd-agentic-input-handling/multi_touch_gestures.gd)
- [`safe_runtime_rebind.gd`](../scripts/gd-agentic-input-handling/safe_runtime_rebind.gd)
- [`unhandled_input_priority.gd`](../scripts/gd-agentic-input-handling/unhandled_input_priority.gd)
- [`virtual_input_injector.gd`](../scripts/gd-agentic-input-handling/virtual_input_injector.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-ui-theming
description: "Use when applying the godot-ui-theming capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-ui-theming

This Builda skill adapts the upstream `godot-ui-theming` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: ux-interface-role
- Canonical Builda owners: **godot-ui**

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

- [`crisp_ui_scaler.gd`](../scripts/gd-agentic-ui-theming/crisp_ui_scaler.gd)
- [`custom_chart_drawing.gd`](../scripts/gd-agentic-ui-theming/custom_chart_drawing.gd)
- [`danger_button_assignment.gd`](../scripts/gd-agentic-ui-theming/danger_button_assignment.gd)
- [`dynamic_stylebox_color.gd`](../scripts/gd-agentic-ui-theming/dynamic_stylebox_color.gd)
- [`focus_prompt_icon_swapper.gd`](../scripts/gd-agentic-ui-theming/focus_prompt_icon_swapper.gd)
- [`global_theme_manager.gd`](../scripts/gd-agentic-ui-theming/global_theme_manager.gd)
- [`memory_safe_custom_drawing.gd`](../scripts/gd-agentic-ui-theming/memory_safe_custom_drawing.gd)
- [`procedural_theme_safe.gd`](../scripts/gd-agentic-ui-theming/procedural_theme_safe.gd)
- [`pulsating_ui_theme.gd`](../scripts/gd-agentic-ui-theming/pulsating_ui_theme.gd)
- [`rtl_theme_mirroring.gd`](../scripts/gd-agentic-ui-theming/rtl_theme_mirroring.gd)
- [`theme_isolation.gd`](../scripts/gd-agentic-ui-theming/theme_isolation.gd)
- [`theme_swapper.gd`](../scripts/gd-agentic-ui-theming/theme_swapper.gd)
- [`ui_scale_manager.gd`](../scripts/gd-agentic-ui-theming/ui_scale_manager.gd)

<!-- builda-script-index:end -->

---
name: gd-agentic-tweening
description: "Use when applying the godot-tweening capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-tweening

This Builda skill adapts the upstream `godot-tweening` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **tween-animation**

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

- [`camera_shake_tween_logic.gd`](../scripts/gd-agentic-tweening/camera_shake_tween_logic.gd)
- [`custom_curve_tween.gd`](../scripts/gd-agentic-tweening/custom_curve_tween.gd)
- [`juice_manager.gd`](../scripts/gd-agentic-tweening/juice_manager.gd)
- [`looped_hover_vfx.gd`](../scripts/gd-agentic-tweening/looped_hover_vfx.gd)
- [`nested_subtween_cutscene.gd`](../scripts/gd-agentic-tweening/nested_subtween_cutscene.gd)
- [`parallel_popup_animation.gd`](../scripts/gd-agentic-tweening/parallel_popup_animation.gd)
- [`relative_recoil_tween.gd`](../scripts/gd-agentic-tweening/relative_recoil_tween.gd)
- [`safe_tween_interruption.gd`](../scripts/gd-agentic-tweening/safe_tween_interruption.gd)
- [`staggered_inventory_entry.gd`](../scripts/gd-agentic-tweening/staggered_inventory_entry.gd)
- [`text_counter_method_tween.gd`](../scripts/gd-agentic-tweening/text_counter_method_tween.gd)
- [`time_scale_ignored_ui.gd`](../scripts/gd-agentic-tweening/time_scale_ignored_ui.gd)
- [`tween_builder.gd`](../scripts/gd-agentic-tweening/tween_builder.gd)

<!-- builda-script-index:end -->

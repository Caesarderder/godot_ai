---
name: gd-agentic-ui-rich-text
description: "Use when applying the godot-ui-rich-text capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-ui-rich-text

This Builda skill adapts the upstream `godot-ui-rich-text` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: ux-interface-role
- Canonical Builda owners: **godot-ui**, **localization**

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

- [`custom_bbcode_effect.gd`](../scripts/gd-agentic-ui-rich-text/custom_bbcode_effect.gd)
- [`rich_text_animator.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_animator.gd)
- [`rich_text_auto_scroller.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_auto_scroller.gd)
- [`rich_text_bbcode_sanitizer.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_bbcode_sanitizer.gd)
- [`rich_text_glitch_effect.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_glitch_effect.gd)
- [`rich_text_gradient_generator.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_gradient_generator.gd)
- [`rich_text_hover_reactive.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_hover_reactive.gd)
- [`rich_text_image_scaler.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_image_scaler.gd)
- [`rich_text_meta_dispatch.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_meta_dispatch.gd)
- [`rich_text_rainbow_effect.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_rainbow_effect.gd)
- [`rich_text_syntax_highlighter.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_syntax_highlighter.gd)
- [`rich_text_typewriter_controller.gd`](../scripts/gd-agentic-ui-rich-text/rich_text_typewriter_controller.gd)

<!-- builda-script-index:end -->

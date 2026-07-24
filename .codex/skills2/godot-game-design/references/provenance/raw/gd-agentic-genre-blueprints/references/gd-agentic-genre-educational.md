---
name: gd-agentic-genre-educational
description: "Use when applying the godot-genre-educational capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-educational

This Builda skill adapts the upstream `godot-genre-educational` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-design-role
- Canonical Builda owners: **game-design**, **game-prototype**

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

- [`adaptive_difficulty_adjuster.gd`](../scripts/gd-agentic-genre-educational/adaptive_difficulty_adjuster.gd)
- [`adaptive_ui_anchors.gd`](../scripts/gd-agentic-genre-educational/adaptive_ui_anchors.gd)
- [`assessment_pause_handler.gd`](../scripts/gd-agentic-genre-educational/assessment_pause_handler.gd)
- [`dynamic_localization.gd`](../scripts/gd-agentic-genre-educational/dynamic_localization.gd)
- [`focus_navigation_manager.gd`](../scripts/gd-agentic-genre-educational/focus_navigation_manager.gd)
- [`interactive_rich_text.gd`](../scripts/gd-agentic-genre-educational/interactive_rich_text.gd)
- [`low_processor_optimizer.gd`](../scripts/gd-agentic-genre-educational/low_processor_optimizer.gd)
- [`spaced_repetition_scheduler.gd`](../scripts/gd-agentic-genre-educational/spaced_repetition_scheduler.gd)
- [`student_profile.gd`](../scripts/gd-agentic-genre-educational/student_profile.gd)
- [`student_progress_config.gd`](../scripts/gd-agentic-genre-educational/student_progress_config.gd)
- [`text_reveal_effect.gd`](../scripts/gd-agentic-genre-educational/text_reveal_effect.gd)
- [`threaded_scoring_engine.gd`](../scripts/gd-agentic-genre-educational/threaded_scoring_engine.gd)
- [`tts_manager.gd`](../scripts/gd-agentic-genre-educational/tts_manager.gd)

<!-- builda-script-index:end -->

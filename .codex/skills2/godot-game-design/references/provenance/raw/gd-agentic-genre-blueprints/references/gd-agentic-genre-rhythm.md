---
name: gd-agentic-genre-rhythm
description: "Use when applying the godot-genre-rhythm capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-rhythm

This Builda skill adapts the upstream `godot-genre-rhythm` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: game-design-role
- Canonical Builda owners: **rhythm-gameplay**, **game-design**

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

- [`audio_spectrum_analyzer.gd`](../scripts/gd-agentic-genre-rhythm/audio_spectrum_analyzer.gd)
- [`beat_synced_animator.gd`](../scripts/gd-agentic-genre-rhythm/beat_synced_animator.gd)
- [`dynamic_bpm_handler.gd`](../scripts/gd-agentic-genre-rhythm/dynamic_bpm_handler.gd)
- [`input_judge_logic.gd`](../scripts/gd-agentic-genre-rhythm/input_judge_logic.gd)
- [`latency_calibrator.gd`](../scripts/gd-agentic-genre-rhythm/latency_calibrator.gd)
- [`note_lane_manager.gd`](../scripts/gd-agentic-genre-rhythm/note_lane_manager.gd)
- [`note_object_pool.gd`](../scripts/gd-agentic-genre-rhythm/note_object_pool.gd)
- [`note_orchestrator.gd`](../scripts/gd-agentic-genre-rhythm/note_orchestrator.gd)
- [`rhythm_conductor.gd`](../scripts/gd-agentic-genre-rhythm/rhythm_conductor.gd)
- [`rhythm_scoring_system.gd`](../scripts/gd-agentic-genre-rhythm/rhythm_scoring_system.gd)
- [`rhythm_ui_feedback.gd`](../scripts/gd-agentic-genre-rhythm/rhythm_ui_feedback.gd)
- [`score_combo_manager.gd`](../scripts/gd-agentic-genre-rhythm/score_combo_manager.gd)

<!-- builda-script-index:end -->

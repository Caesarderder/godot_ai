---
name: gd-agentic-mechanic-secrets
description: "Use when applying the godot-mechanic-secrets capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-mechanic-secrets

This Builda skill adapts the upstream `godot-mechanic-secrets` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **objective-loop**, **game-design**

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

- [`input_sequence_watcher.gd`](../scripts/gd-agentic-mechanic-secrets/input_sequence_watcher.gd)
- [`interaction_threshold_trigger.gd`](../scripts/gd-agentic-mechanic-secrets/interaction_threshold_trigger.gd)
- [`secret_audio_environment_occluder.gd`](../scripts/gd-agentic-mechanic-secrets/secret_audio_environment_occluder.gd)
- [`secret_interaction_spam_tracker.gd`](../scripts/gd-agentic-mechanic-secrets/secret_interaction_spam_tracker.gd)
- [`secret_konami_legacy_code.gd`](../scripts/gd-agentic-mechanic-secrets/secret_konami_legacy_code.gd)
- [`secret_lockout_cheat_guard.gd`](../scripts/gd-agentic-mechanic-secrets/secret_lockout_cheat_guard.gd)
- [`secret_meta_persistence.gd`](../scripts/gd-agentic-mechanic-secrets/secret_meta_persistence.gd)
- [`secret_persistence_handler.gd`](../scripts/gd-agentic-mechanic-secrets/secret_persistence_handler.gd)
- [`secret_progress_threshold_unlocker.gd`](../scripts/gd-agentic-mechanic-secrets/secret_progress_threshold_unlocker.gd)
- [`secret_random_encounter_spawner.gd`](../scripts/gd-agentic-mechanic-secrets/secret_random_encounter_spawner.gd)
- [`secret_sequence_combo_matcher.gd`](../scripts/gd-agentic-mechanic-secrets/secret_sequence_combo_matcher.gd)
- [`secret_vfx_discovery_glimmer.gd`](../scripts/gd-agentic-mechanic-secrets/secret_vfx_discovery_glimmer.gd)
- [`secret_visibility_detector.gd`](../scripts/gd-agentic-mechanic-secrets/secret_visibility_detector.gd)

<!-- builda-script-index:end -->

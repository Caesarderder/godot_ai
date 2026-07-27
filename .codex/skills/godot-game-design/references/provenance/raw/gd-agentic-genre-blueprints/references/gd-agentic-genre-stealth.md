---
name: gd-agentic-genre-stealth
description: "Use when applying the godot-genre-stealth capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-genre-stealth

This Builda skill adapts the upstream `godot-genre-stealth` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`alert_indicator.gd`](../scripts/gd-agentic-genre-stealth/alert_indicator.gd)
- [`enemy_ai.gd`](../scripts/gd-agentic-genre-stealth/enemy_ai.gd)
- [`enemy_vision.gd`](../scripts/gd-agentic-genre-stealth/enemy_vision.gd)
- [`light_detector.gd`](../scripts/gd-agentic-genre-stealth/light_detector.gd)
- [`sound_occlusion_manager.gd`](../scripts/gd-agentic-genre-stealth/sound_occlusion_manager.gd)
- [`sound_propagation.gd`](../scripts/gd-agentic-genre-stealth/sound_propagation.gd)
- [`stealth_ai_controller.gd`](../scripts/gd-agentic-genre-stealth/stealth_ai_controller.gd)
- [`stealth_hud.gd`](../scripts/gd-agentic-genre-stealth/stealth_hud.gd)
- [`stealth_patterns.gd`](../scripts/gd-agentic-genre-stealth/stealth_patterns.gd)
- [`stealth_vision_cone.gd`](../scripts/gd-agentic-genre-stealth/stealth_vision_cone.gd)
- [`visibility_manager.gd`](../scripts/gd-agentic-genre-stealth/visibility_manager.gd)
- [`vision_cone_3d.gd`](../scripts/gd-agentic-genre-stealth/vision_cone_3d.gd)

<!-- builda-script-index:end -->

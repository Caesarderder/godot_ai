---
name: gd-agentic-scene-management
description: "Use when applying the godot-scene-management capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-scene-management

This Builda skill adapts the upstream `godot-scene-management` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`additive_ui_layering.gd`](../scripts/gd-agentic-scene-management/additive_ui_layering.gd)
- [`async_scene_manager.gd`](../scripts/gd-agentic-scene-management/async_scene_manager.gd)
- [`background_resource_loader.gd`](../scripts/gd-agentic-scene-management/background_resource_loader.gd)
- [`dynamic_script_attachment.gd`](../scripts/gd-agentic-scene-management/dynamic_script_attachment.gd)
- [`node_path_safe_retrieval.gd`](../scripts/gd-agentic-scene-management/node_path_safe_retrieval.gd)
- [`node_unparent_reparent.gd`](../scripts/gd-agentic-scene-management/node_unparent_reparent.gd)
- [`persistent_data_preservation.gd`](../scripts/gd-agentic-scene-management/persistent_data_preservation.gd)
- [`scene_instancing_pooling.gd`](../scripts/gd-agentic-scene-management/scene_instancing_pooling.gd)
- [`scene_pool.gd`](../scripts/gd-agentic-scene-management/scene_pool.gd)
- [`scene_state_manager.gd`](../scripts/gd-agentic-scene-management/scene_state_manager.gd)
- [`scene_transition_manager.gd`](../scripts/gd-agentic-scene-management/scene_transition_manager.gd)
- [`subviewport_scene_layering.gd`](../scripts/gd-agentic-scene-management/subviewport_scene_layering.gd)

<!-- builda-script-index:end -->

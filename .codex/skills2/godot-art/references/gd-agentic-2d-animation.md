---
name: gd-agentic-2d-animation
description: "Use when applying the godot-2d-animation capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-2d-animation

This Builda skill adapts the upstream `godot-2d-animation` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **animation-system**

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

- [`animation_data_extractor.gd`](../scripts/gd-agentic-2d-animation/animation_data_extractor.gd)
- [`animation_state_sync.gd`](../scripts/gd-agentic-2d-animation/animation_state_sync.gd)
- [`animation_sync.gd`](../scripts/gd-agentic-2d-animation/animation_sync.gd)
- [`animation_tree_step.gd`](../scripts/gd-agentic-2d-animation/animation_tree_step.gd)
- [`gpu_mesh_optimizer.gd`](../scripts/gd-agentic-2d-animation/gpu_mesh_optimizer.gd)
- [`multimesh_swarm_anim.gd`](../scripts/gd-agentic-2d-animation/multimesh_swarm_anim.gd)
- [`one_frame_sync_fix.gd`](../scripts/gd-agentic-2d-animation/one_frame_sync_fix.gd)
- [`procedural_squash_stretch.gd`](../scripts/gd-agentic-2d-animation/procedural_squash_stretch.gd)
- [`procedural_walker_2d.gd`](../scripts/gd-agentic-2d-animation/procedural_walker_2d.gd)
- [`shader_hook.gd`](../scripts/gd-agentic-2d-animation/shader_hook.gd)
- [`skeleton_2d_rig_helper.gd`](../scripts/gd-agentic-2d-animation/skeleton_2d_rig_helper.gd)
- [`sprite_sheet_memory_manager.gd`](../scripts/gd-agentic-2d-animation/sprite_sheet_memory_manager.gd)
- [`tween_lifecycle_manager.gd`](../scripts/gd-agentic-2d-animation/tween_lifecycle_manager.gd)

<!-- builda-script-index:end -->

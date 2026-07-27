---
name: gd-agentic-composition
description: "Use when applying the godot-composition capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-composition

This Builda skill adapts the upstream `godot-composition` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`composition_root_init.gd`](../scripts/gd-agentic-composition/composition_root_init.gd)
- [`follower_component.gd`](../scripts/gd-agentic-composition/follower_component.gd)
- [`health_component.gd`](../scripts/gd-agentic-composition/health_component.gd)
- [`hit_box_component.gd`](../scripts/gd-agentic-composition/hit_box_component.gd)
- [`hurt_box_component.gd`](../scripts/gd-agentic-composition/hurt_box_component.gd)
- [`interaction_component.gd`](../scripts/gd-agentic-composition/interaction_component.gd)
- [`state_component_vsm.gd`](../scripts/gd-agentic-composition/state_component_vsm.gd)
- [`status_effect_component.gd`](../scripts/gd-agentic-composition/status_effect_component.gd)
- [`velocity_component.gd`](../scripts/gd-agentic-composition/velocity_component.gd)
- [`visual_sync_component.gd`](../scripts/gd-agentic-composition/visual_sync_component.gd)

<!-- builda-script-index:end -->

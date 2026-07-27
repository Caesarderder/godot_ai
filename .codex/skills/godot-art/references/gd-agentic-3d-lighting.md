---
name: gd-agentic-3d-lighting
description: "Use when applying the godot-3d-lighting capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-3d-lighting

This Builda skill adapts the upstream `godot-3d-lighting` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **3d-essentials**, **game-visual-design**

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

- [`day_night_cycle.gd`](../scripts/gd-agentic-3d-lighting/day_night_cycle.gd)
- [`environment_blender.gd`](../scripts/gd-agentic-3d-lighting/environment_blender.gd)
- [`fake_gi_bounce.gd`](../scripts/gd-agentic-3d-lighting/fake_gi_bounce.gd)
- [`light_lod_optimizer.gd`](../scripts/gd-agentic-3d-lighting/light_lod_optimizer.gd)
- [`light_probe_manager.gd`](../scripts/gd-agentic-3d-lighting/light_probe_manager.gd)
- [`light_volume_trigger.gd`](../scripts/gd-agentic-3d-lighting/light_volume_trigger.gd)
- [`lighting_manager.gd`](../scripts/gd-agentic-3d-lighting/lighting_manager.gd)
- [`lighting_quality_manager.gd`](../scripts/gd-agentic-3d-lighting/lighting_quality_manager.gd)
- [`lightmap_bake_helper.gd`](../scripts/gd-agentic-3d-lighting/lightmap_bake_helper.gd)
- [`reflection_probe_manager.gd`](../scripts/gd-agentic-3d-lighting/reflection_probe_manager.gd)
- [`sdfgi_probe_manager.gd`](../scripts/gd-agentic-3d-lighting/sdfgi_probe_manager.gd)
- [`shadow_bias_tuner.gd`](../scripts/gd-agentic-3d-lighting/shadow_bias_tuner.gd)
- [`shadow_cascade_tuner.gd`](../scripts/gd-agentic-3d-lighting/shadow_cascade_tuner.gd)
- [`spotlight_projector_setup.gd`](../scripts/gd-agentic-3d-lighting/spotlight_projector_setup.gd)
- [`volumetric_fog_zones.gd`](../scripts/gd-agentic-3d-lighting/volumetric_fog_zones.gd)
- [`volumetric_fx.gd`](../scripts/gd-agentic-3d-lighting/volumetric_fx.gd)

<!-- builda-script-index:end -->

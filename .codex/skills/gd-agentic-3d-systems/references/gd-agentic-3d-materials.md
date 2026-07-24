---
name: gd-agentic-3d-materials
description: "Use when applying the godot-3d-materials capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-3d-materials

This Builda skill adapts the upstream `godot-3d-materials` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **shader-basics**, **3d-essentials**

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

- [`decal_placer_expert.gd`](../scripts/gd-agentic-3d-materials/decal_placer_expert.gd)
- [`depth_precision_fix.gd`](../scripts/gd-agentic-3d-materials/depth_precision_fix.gd)
- [`instance_uniform_batching.gdshader`](../scripts/gd-agentic-3d-materials/instance_uniform_batching.gdshader)
- [`material_batcher.gd`](../scripts/gd-agentic-3d-materials/material_batcher.gd)
- [`material_fx.gd`](../scripts/gd-agentic-3d-materials/material_fx.gd)
- [`organic_material.gd`](../scripts/gd-agentic-3d-materials/organic_material.gd)
- [`pbr_material_builder.gd`](../scripts/gd-agentic-3d-materials/pbr_material_builder.gd)
- [`pbr_orm_packer.gd`](../scripts/gd-agentic-3d-materials/pbr_orm_packer.gd)
- [`shader_state_manager.gd`](../scripts/gd-agentic-3d-materials/shader_state_manager.gd)
- [`subsurface_scattering_setup.gd`](../scripts/gd-agentic-3d-materials/subsurface_scattering_setup.gd)
- [`transparency_sorting_fix.gd`](../scripts/gd-agentic-3d-materials/transparency_sorting_fix.gd)
- [`triplanar_world.gdshader`](../scripts/gd-agentic-3d-materials/triplanar_world.gdshader)
- [`triplanar_world_projection.gdshader`](../scripts/gd-agentic-3d-materials/triplanar_world_projection.gdshader)
- [`vertex_wind_sway.gdshader`](../scripts/gd-agentic-3d-materials/vertex_wind_sway.gdshader)

<!-- builda-script-index:end -->

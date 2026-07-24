---
name: gd-agentic-shaders-basics
description: "Use when applying the godot-shaders-basics capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-shaders-basics

This Builda skill adapts the upstream `godot-shaders-basics` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **shader-basics**

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

- [`depth_world_reconstruction.gdshader`](../scripts/gd-agentic-shaders-basics/depth_world_reconstruction.gdshader)
- [`dissolve_scissor_expert.gdshader`](../scripts/gd-agentic-shaders-basics/dissolve_scissor_expert.gdshader)
- [`foliage_wind_sway_expert.gdshader`](../scripts/gd-agentic-shaders-basics/foliage_wind_sway_expert.gdshader)
- [`global_grass_flatten.gdshader`](../scripts/gd-agentic-shaders-basics/global_grass_flatten.gdshader)
- [`instance_texture_array.gdshader`](../scripts/gd-agentic-shaders-basics/instance_texture_array.gdshader)
- [`instance_uniform_hitflash.gdshader`](../scripts/gd-agentic-shaders-basics/instance_uniform_hitflash.gdshader)
- [`noise_terrain_displacement.gdshader`](../scripts/gd-agentic-shaders-basics/noise_terrain_displacement.gdshader)
- [`screenspace_full_quad.gdshader`](../scripts/gd-agentic-shaders-basics/screenspace_full_quad.gdshader)
- [`screenspace_hex_pixelate.gdshader`](../scripts/gd-agentic-shaders-basics/screenspace_hex_pixelate.gdshader)
- [`shader_parameter_animator.gd`](../scripts/gd-agentic-shaders-basics/shader_parameter_animator.gd)
- [`shader_warmup_loader.gd`](../scripts/gd-agentic-shaders-basics/shader_warmup_loader.gd)
- [`triplanar_world_mapping.gdshader`](../scripts/gd-agentic-shaders-basics/triplanar_world_mapping.gdshader)
- [`vfx_port_shader.gdshader`](../scripts/gd-agentic-shaders-basics/vfx_port_shader.gdshader)

<!-- builda-script-index:end -->

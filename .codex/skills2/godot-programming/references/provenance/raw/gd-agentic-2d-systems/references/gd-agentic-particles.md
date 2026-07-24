---
name: gd-agentic-particles
description: "Use when applying the godot-particles capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-particles

This Builda skill adapts the upstream `godot-particles` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: audiovisual-role
- Canonical Builda owners: **particles-vfx**

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

- [`2d_physics_interpolation_fix.gd`](../scripts/gd-agentic-particles/2d_physics_interpolation_fix.gd)
- [`custom_particle_logic.gdshader`](../scripts/gd-agentic-particles/custom_particle_logic.gdshader)
- [`dynamic_userdata_modulation.gd`](../scripts/gd-agentic-particles/dynamic_userdata_modulation.gd)
- [`local_vs_global_coords.gd`](../scripts/gd-agentic-particles/local_vs_global_coords.gd)
- [`massive_swarm_multimesh.gd`](../scripts/gd-agentic-particles/massive_swarm_multimesh.gd)
- [`particle_attractor_opt.gd`](../scripts/gd-agentic-particles/particle_attractor_opt.gd)
- [`particle_burst_emitter.gd`](../scripts/gd-agentic-particles/particle_burst_emitter.gd)
- [`particle_lod_manager.gd`](../scripts/gd-agentic-particles/particle_lod_manager.gd)
- [`screenspace_weather_heightfield.gd`](../scripts/gd-agentic-particles/screenspace_weather_heightfield.gd)
- [`smart_oneshot_recycler.gd`](../scripts/gd-agentic-particles/smart_oneshot_recycler.gd)
- [`sub_emitter_impact.gdshader`](../scripts/gd-agentic-particles/sub_emitter_impact.gdshader)
- [`vfx_pool_manager.gd`](../scripts/gd-agentic-particles/vfx_pool_manager.gd)
- [`vfx_shader_manager.gd`](../scripts/gd-agentic-particles/vfx_shader_manager.gd)

<!-- builda-script-index:end -->

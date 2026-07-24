---
name: particles-vfx
description: Build or review Godot 4.6.x particle effects in GDScript for Builda's single-threaded Web runtime and Compatibility renderer. Use for GPUParticles2D/3D, CPUParticles2D/3D, ParticleProcessMaterial, one-shot effects, pooling, emission, flipbooks, subemitters, and measured Web budgets.
---

# Particles and VFX

Target Godot 4.6.x, GDScript, single-threaded Web, and the Compatibility renderer.

## Renderer boundary

Use core particle emission and material features verified in Compatibility. Do not design around particle trails, particle signed-distance-field collision, advanced renderer-only attractor/collision paths, compute-driven custom pipelines, or other unsupported rendering features.

Test the exported Web effect. Editor playback on another renderer is not evidence that the effect works or has the same cost in Compatibility.

## Choose GPU or CPU particles

Start with `GPUParticles2D` or `GPUParticles3D` for ordinary visual effects. Use CPU particles only when a required behavior is unavailable on the GPU path and the measured particle count is small enough for Web.

Keep amount, lifetime, draw-pass complexity, transparency overdraw, and simultaneous emitters within a defined effect budget.

## Basic one-shot effect

```gdscript
extends GPUParticles2D

func play_once(at_position: Vector2) -> void:
    global_position = at_position
    restart()
    emitting = true
```

Configure `one_shot`, `lifetime`, and `explosiveness` in the resource. If the effect node should free itself, use a timer or a small owner that accounts for lifetime and preprocess rather than polling every particle.

## ParticleProcessMaterial

Use `ParticleProcessMaterial` for:

- emission shape;
- initial velocity and spread;
- gravity and acceleration;
- angular velocity;
- scale and color curves;
- damping and orbit where supported.

Keep curves and gradients as reusable Resources. Duplicate them only when an instance intentionally mutates its own copy.

For 2D flipbooks, configure sprite-sheet frames in the draw material and animation speed/offset in the process material. Verify frame order and filtering in Web.

## Subemitters

Use subemitters for a bounded second stage such as sparks from an impact. Confirm parent-child lifetime, local/global coordinates, and pool reset behavior. Avoid deep subemitter chains; they make count and lifetime budgets hard to predict.

## Pooling and restart

Pool only frequently spawned effects. A pooled emitter must reset:

- transform and visibility;
- `emitting` and restart state;
- process material parameters changed at runtime;
- modulate/material overrides;
- owner callbacks or timers.

Do not return an emitter to the pool based only on a guessed delay if speed scale or lifetime can change.

## Overdraw and Web performance

- Prefer small particle quads and tight transparent bounds.
- Avoid many large translucent layers covering the viewport.
- Share meshes and materials where variation can be expressed by instance parameters.
- Reduce simultaneous emitters before reducing every effect's readability.
- Measure GPU frame time and browser memory with representative combat/action density.
- Provide a reduced-effects product setting when target devices vary widely.

## Runtime validation

- Re-enter a pooled effect several times and check stale state.
- Pause/resume and change time scale.
- Move the emitter while local coordinates are enabled and disabled.
- Check scene exit before a one-shot completes.
- Compare at least one low-end target browser/device with the desktop editor.

## References boundary

No bundled reference is required by default. Existing files under `references/` are optional legacy recipes and may contain other languages, engine versions, or unsupported renderer features. Do not load them automatically. Reuse only target-compatible behavior after verifying it in the Web export.

## Checklist

- [ ] Effect uses only Compatibility-supported features.
- [ ] GPU versus CPU choice is based on required behavior and measurement.
- [ ] Particle count, lifetime, and overdraw are bounded.
- [ ] Shared Resources are not accidentally mutated per instance.
- [ ] Pooled emitters fully reset.
- [ ] Subemitter chains remain shallow and predictable.
- [ ] Exported Web visuals and performance are verified.

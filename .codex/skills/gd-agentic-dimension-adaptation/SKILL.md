---
name: gd-agentic-dimension-adaptation
description: "Use when converting a tenant Godot game between 2D and 3D while retaining gameplay intent, project ownership, Web constraints, and verifiable preview behavior"
---

# GD-Agentic Dimension Adaptation

Choose exactly one primary direction, then load supporting 2D or 3D system references only when the conversion requires them.

## Route

| Direction | Read |
| --- | --- |
| Convert a 2D game or subsystem to 3D | [2D to 3D](references/gd-agentic-adapt-2d-to-3d.md) |
| Convert a 3D game or subsystem to 2D | [3D to 2D](references/gd-agentic-adapt-3d-to-2d.md) |

## Script prototypes

After selecting one direction, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Apply only the files compatible with the chosen direction and the current project.

## Apply

1. Record the gameplay, camera, collision, input, and presentation invariants that must survive.
2. Read the single direction reference.
3. Plan scene/resource migrations without breaking paths, `.uid` identity, or thin project roots.
4. Keep the result within Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime.
5. Verify converted mechanics and visual intent in the real Web preview.

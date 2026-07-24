---
name: gd-agentic-2d-systems
description: "Use for Godot 4.6 Web 2D systems: animation, CharacterBody2D movement, collision queries, cameras, particles, CanvasItem shaders, TileMap, and tweened game feel"
---

# GD-Agentic 2D Systems

Route 2D implementation to the smallest relevant reference. Do not load every reference by default.

## Route

| Need | Read |
| --- | --- |
| Sprite, cutout, or procedural 2D animation | [2D animation](references/gd-agentic-2d-animation.md) |
| 2D collisions, triggers, and physics queries | [2D physics](references/gd-agentic-2d-physics.md) |
| Timeline tracks and RESET behavior | [AnimationPlayer](references/gd-agentic-animation-player.md) |
| Blend spaces and layered animation state | [AnimationTree](references/gd-agentic-animation-tree-mastery.md) |
| Follow, deadzone, and shake behavior | [camera systems](references/gd-agentic-camera-systems.md) |
| Platformer movement and collision handling | [CharacterBody2D](references/gd-agentic-characterbody-2d.md) |
| Web-compatible particle feedback | [particles](references/gd-agentic-particles.md) |
| CanvasItem shaders and post effects | [shader basics](references/gd-agentic-shaders-basics.md) |
| TileMap authoring and runtime changes | [TileMap mastery](references/gd-agentic-tilemap-mastery.md) |
| Easing and moment-to-moment feedback | [tweening](references/gd-agentic-tweening.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Reject or rewrite APIs that violate Godot 4.6 Web, Compatibility, single-thread, project ownership, or protected-core rules.

## Apply

1. Inspect the current scene, scripts, and renderer constraints.
2. Read only the references needed for the requested behavior.
3. Preserve scene ownership, node identity, `.uid` pairing, and canonical asset paths.
4. Avoid native-only APIs, unsupported renderer features, and multithreaded assumptions.
5. Verify the focused scene and the real Web preview.

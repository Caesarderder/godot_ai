---
name: gd-agentic-3d-systems
description: "Use for Godot 4.6 Web 3D systems: lighting, materials, world building, navigation, physics, procedural generation, ray and shape queries, and AI navigation"
---

# GD-Agentic 3D Systems

Route 3D implementation to the smallest relevant reference. Do not load every reference by default.

## Route

| Need | Read |
| --- | --- |
| Web-compatible lights and shadows | [3D lighting](references/gd-agentic-3d-lighting.md) |
| PBR materials and transparency | [3D materials](references/gd-agentic-3d-materials.md) |
| GridMap, CSG, and environment construction | [3D world building](references/gd-agentic-3d-world-building.md) |
| Agent movement, NavigationAgent, avoidance, and pathfinding | [navigation and pathfinding](references/gd-agentic-navigation-pathfinding.md) |
| CharacterBody3D and rigid-body behavior | [3D physics](references/gd-agentic-physics-3d.md) |
| Noise, WFC, and chunked generation | [procedural generation](references/gd-agentic-procedural-generation.md) |
| RayCast, ShapeCast, LOS, and picking | [raycasting and queries](references/gd-agentic-raycasting-queries.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Reject or rewrite forward-renderer, multithreaded, native, or unbounded workloads that violate the Builda Web target.

## Apply

1. Inspect project renderer, scene scale, collision layers, and performance budget.
2. Read only the references needed for the requested subsystem.
3. Treat [AI navigation](references/gd-agentic-ai-navigation.md) as a preserved compatibility alias; do not load it together with navigation and pathfinding.
4. Prefer Compatibility-renderer techniques and bounded single-thread workloads.
5. Preserve scene/resource ownership and canonical asset paths.
6. Verify focused behavior, frame cost, and the real Web preview.

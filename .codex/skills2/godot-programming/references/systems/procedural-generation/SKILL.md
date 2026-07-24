---
name: procedural-generation
description: Use when implementing deterministic Godot 4.6 GDScript seeded procedural generation with noise, grids, random walks, BSP, cellular rules, or wave-function-collapse-like constraints for Web
---

# Procedural Generation for Godot 4.6 Web

Own deterministic generation algorithms and their bounded execution. Reuse **game-level-design** for playable-space intent, **2d-essentials** or **3d-essentials** for world realization, **resource-pattern** for definitions, **save-load** for seed/state persistence, and **godot-optimization** for measured performance work.

## Determinism contract

Create a local `RandomNumberGenerator`; set and record its seed. Never depend on unrelated global random calls. A generation request includes algorithm version, seed, dimensions, constraints, and content-set IDs. The same admitted inputs must produce the same logical output.

Separate generation from scene instantiation:

`validate inputs -> produce plain grid/graph/data -> validate output -> instantiate bounded chunks`

This makes failures testable and keeps scene-tree side effects out of backtracking.

## Algorithms

- Noise: sample coordinates consistently and classify with explicit thresholds.
- Random walk/cellular: cap steps/iterations and validate connectedness.
- BSP: enforce minimum partition and room sizes before splitting.
- Constraint propagation: choose the lowest-entropy cell, propagate, backtrack with a strict budget, and return failure rather than looping forever.
- Chunk generation: use deterministic chunk coordinates and main-thread time slicing; default Builda Web work does not assume worker threads.

## Safety and integration

Reject unbounded dimensions, empty rule sets, impossible adjacency tables, and unknown content IDs. Keep file writes, project settings, imported assets, and scene ownership outside this skill. If regeneration across releases matters, persist algorithm version as well as seed.

## Verification

Test same-seed equality, different-seed variation, invariants, impossible constraints, maximum-size budgets, disconnected output, version migration, and cancellation between chunks. Measure actual Web frame cost; deterministic tests do not prove a generated level is navigable or fun.

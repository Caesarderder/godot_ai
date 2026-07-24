---
name: physics-system
description: Use when working with physics bodies, collision shapes, raycasting, areas, rigid bodies, ragdolls, soft bodies, Jolt physics, and physics interpolation in Godot 4.6 GDScript projects
---

# Physics System in Godot 4.6

Use the GDScript examples and APIs supported by Godot 4.6. Builda Web uses the single-threaded export runtime.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

> **Related skills:** **player-controller** for CharacterBody2D/3D movement patterns, **godot-architecture** for hitbox/hurtbox ownership, **godot-optimization** for physics performance tuning, **camera-system** for camera follow and interpolation, and **2d-essentials** for tile collision setup and 2D canvas layers.

---

## 1. Physics Body Types

Four collision-object types (the last three extend `PhysicsBody2D`/`3D`):

| Type | Moved by | Use for |
|------|----------|---------|
| `Area2D/3D` | Code | Overlap detection, gravity zones, audio zones |
| `StaticBody2D/3D` | Not moved (or `constant_linear_velocity`) | Walls, floors, conveyor belts |
| `RigidBody2D/3D` | Physics engine | Crates, projectiles, debris, ragdolls |
| `CharacterBody2D/3D` | Code | Players, enemies, NPCs (see **player-controller**) |

Every collision object needs at least one `CollisionShape2D`/`3D` (or `CollisionPolygon2D`/`3D`) child. In Godot 4.6, Jolt is the stable default 3D engine; 2D uses GodotPhysics.

> **Critical rule:** NEVER scale collision shapes or physics bodies via `scale`. Use the shape's own size parameters (radius, extents, height) — scaled shapes produce incorrect collision results.

---

## 2. RigidBody2D/3D

### Forces vs Impulses

| Method | Effect | When to use |
|---|---|---|
| `apply_force(force, position)` | Continuous accel at point | Thrusters, wind, magnets |
| `apply_central_force(force)` | Continuous accel at center | Gravity, constant push |
| `apply_impulse(impulse, position)` | Instant velocity change at point | Bullet hit, explosion |
| `apply_central_impulse(impulse)` | Instant velocity change at center | Jump, knockback |
| `apply_torque(torque)` | Continuous angular accel | Steering, spinning |
| `apply_torque_impulse(impulse)` | Instant angular velocity change | Impact spin |

> See [references/rigidbody-recipes.md](references/rigidbody-recipes.md) for the GDScript thrust-and-spin example.

### _integrate_forces() — Safe Physics Modification

Use `_integrate_forces(state)` instead of `_physics_process()` when you need to read/modify a RigidBody's transform, velocity, or angular velocity. Setting `position` or `linear_velocity` directly in `_physics_process()` fights the physics engine.

> **Warning:** `_integrate_forces()` is NOT called while the body is sleeping. Set `can_sleep = false` if you need continuous callbacks; otherwise prefer letting bodies sleep for performance.

> See [references/rigidbody-recipes.md](references/rigidbody-recipes.md) for the GDScript `state.apply_force` / `state.apply_torque` example.

### Contact Monitoring, PhysicsMaterial, Freeze, look_at

- **Contact signals** require `contact_monitor = true` + `max_contacts_reported > 0`. Then `body_entered`/`body_exited` fire as expected.
- **`PhysicsMaterial`** resource controls `friction` (0 ice → 1 rubber) and `bounce` (0 → 1).
- **Freeze modes:** `FREEZE_MODE_STATIC` (acts like a StaticBody) or `FREEZE_MODE_KINEMATIC` (code-moved, pushes others).
- **RigidBody3D orientation:** never `look_at()` a RigidBody — use `_integrate_forces` and set `state.angular_velocity` from a cross-product steering term.

> See [references/rigidbody-recipes.md](references/rigidbody-recipes.md) for GDScript contact, material, freeze, and steering recipes.

---

## 3. StaticBody2D/3D

`StaticBody` is not moved by the physics engine but can push other bodies via `constant_linear_velocity` (e.g. conveyor belts). For platforms that move via code AND push CharacterBodies, use **`AnimatableBody2D`/`3D`** — a plain `StaticBody` moved by code will not push CharacterBodies reliably.

> See [references/staticbody-recipes.md](references/staticbody-recipes.md) for GDScript conveyor-belt and moving-platform recipes.

---

## 4. Area2D/3D

Areas detect overlaps and override physics properties within their bounds. They do NOT produce collision responses — bodies pass through them. Connect `body_entered` / `body_exited` for body overlaps; use `area_entered` / `area_exited` for Area-to-Area hitbox and hurtbox interactions. Areas can also override gravity (zero-G zones, point gravity / black holes), `linear_damp` / `angular_damp` (water, slow-mo), and redirect audio to a specific `AudioBus`. When multiple areas overlap, `priority` decides order; pick a `space_override` mode (`COMBINE`, `REPLACE`, `COMBINE_REPLACE`, `REPLACE_COMBINE`).

> See [references/area-recipes.md](references/area-recipes.md) for GDScript overlap detection, space overrides, and gravity-area recipes.

---

## 5. Collision Shapes

| Shape (2D / 3D) | Use case |
|---|---|
| `Rectangle` / `Box` | Crates, platforms, rooms |
| `Circle` / `Sphere` | Balls, projectiles, simple characters, trigger zones |
| `Capsule` (2D & 3D) | Characters — rounded, slides over edges |
| `Segment2D` / — | Thin walls, laser beams |
| `SeparationRay2D` / — | Character ground snapping |
| `WorldBoundary2D` / — | Infinite floor/wall/ceiling |
| — / `Cylinder3D` | Pillars, barrels (Jolt only — unstable on GodotPhysics) |

### Convex vs Concave

| Type | Usable with | Cost | Notes |
|---|---|---|---|
| Primitive | All bodies | Cheapest | Always prefer for dynamic bodies |
| `ConvexPolygonShape` | All bodies | Fast | No holes or inward curves |
| `ConcavePolygonShape` | **StaticBody only** | Slowest | Accurate for level geometry; no volume |

**Generate shapes:** for 3D, `MeshInstance3D` → **Mesh** menu → Create Single Convex / Multiple Convex (V-HACD) / Trimesh (ConcavePolygonShape). For 2D, `Sprite2D` → **Sprite2D** menu → Create CollisionPolygon2D Sibling (adjust Simplification / Shrink / Grow).

### Performance Rules

Favor primitives for dynamic bodies; minimize shape count per body (each costs narrow-phase checks); never translate/rotate/scale CollisionShape nodes — a single non-transformed shape enables broad-phase optimization; concave shapes only on StaticBodies (O(n) triangle checks); multiple shapes on one body don't collide with each other (this is correct, not a bug); shapes must be direct children — indirect children are ignored.

## 6. Collision Layers and Masks

Godot provides 32 physics layers per dimension (2D and 3D separately).

- **collision_layer** — which layers this object **exists on** (others scan for it here)
- **collision_mask** — which layers this object **scans** (what it detects)

> **Mental model:** Layer = "I am", Mask = "I scan for". A collision happens when object A's mask includes object B's layer, OR vice versa.

Name layers in **Project Settings → Layer Names → 2D Physics** (or 3D Physics); set them in code with `set_collision_layer_value(N, true)` / `set_collision_mask_value(N, true)` (1-indexed).

> See [references/collision-layers.md](references/collision-layers.md) for layer naming, bitmasks, export flags, and GDScript examples.

---

## 7. Raycasting and Physics Queries

### RayCast2D/3D Nodes (Simple Per-Frame Rays)

Add a `RayCast2D` / `RayCast3D` as a child node — it casts every physics frame automatically. Read with `is_colliding()` and `get_collider()` / `get_collision_point()` / `get_collision_normal()`.

> See [references/raycasting-recipes.md](references/raycasting-recipes.md) for the GDScript RayCast node example.

### Code-Based Raycasting (PhysicsDirectSpaceState)

For on-demand queries, access the space state via `get_world_2d().direct_space_state` (or `get_world_3d()`) and call `intersect_ray(query)` with `PhysicsRayQueryParameters2D/3D.create(from, to)`. Set `query.exclude = [get_rid()]` to skip self, `query.collision_mask` to filter layers. **Only safe inside `_physics_process()`** — the physics space is locked during rendering.

> See [references/raycasting-recipes.md](references/raycasting-recipes.md) for GDScript raycasts with self-exclusion, mask filtering, and 3D mouse picking.

### Ray Result, Other Queries, 3D Mouse Picking

The `intersect_ray` result dictionary contains `position`, `normal`, `collider`, `collider_id`, `rid`, `shape`. `PhysicsDirectSpaceState` also supports `intersect_point` (overlapping shapes at a point), `intersect_shape` (area query), `cast_motion` (shape sweep), `collide_shape` (contact points), `get_rest_info` (resting collision info). For 3D mouse picking, `Camera3D.project_ray_origin(screen_pos)` + `project_ray_normal(screen_pos)` builds the ray.

> See [references/raycasting-recipes.md](references/raycasting-recipes.md) for the GDScript mouse-picking recipe.

---

## 8. Jolt Physics

Jolt is Godot 4.6's stable default engine for new 3D projects.

### Enabling Jolt

**Project Settings → Physics → 3D → Physics Engine** → `Jolt Physics` → Save → Restart editor. (3D only; 2D always uses GodotPhysics.)

### Why & Differences

**Wins:** better stacking stability, reliable `CylinderShape3D`, better `SoftBody3D`, and active-edge detection (fixes ghost collisions).

> See [references/jolt-differences.md](references/jolt-differences.md) for the behavioral differences from GodotPhysics (stabilization, collision margins, single-body joints, `face_index`, unsupported joint properties).

---

## 9. Physics Interpolation

Physics interpolation smooths visual motion between physics ticks when tick rate differs from frame rate. Enable it in **Project Settings → Physics → Common → Physics Interpolation**. Godot 4.6 uses the SceneTree-based 3D interpolation pipeline, including nested transforms.

### Core Rules

1. **Move all game logic to `_physics_process()`** — transforms set outside physics ticks cause jitter
2. **Tweens and AnimationPlayer** that move physics objects must use physics tick timing
3. **Call `reset_physics_interpolation()`** after teleporting or initial placement to prevent "streaking"

> See [references/interpolation-tuning.md](references/interpolation-tuning.md) for the GDScript teleport-reset example, per-node interpolation control, and tick-rate guidance.

### Camera Interpolation

Cameras need special handling under physics interpolation. Make the camera independent (or `top_level = true`), update it in `_process()` (not `_physics_process()`), and read the target's smooth position with `get_global_transform_interpolated()`.

> See [references/interpolation-camera.md](references/interpolation-camera.md) for the GDScript smooth-follow Camera3D recipe.

---

## 10. Ragdoll System

Ragdolls replace animation with physics for procedural death, explosions, or limp characters. Generate via `Skeleton3D` → **Skeleton** menu → **Create Physical Skeleton**. Use `ConeJoint` for shoulders/hips/neck, `HingeJoint` for elbows/knees — `PinJoint` (default) tends to crumple. Drive via `physical_bones_start_simulation()`, blend with `Influence`.

> See [references/ragdoll-recipes.md](references/ragdoll-recipes.md) for setup, GDScript control, animation blending, and collision exceptions.

---

## 11. SoftBody3D

`SoftBody3D` simulates deformable objects (cloth, capes, jelly). Mesh subdivision drives the simulation; no `CollisionShape` child needed. **Jolt Physics recommended.** Set `Simulation Precision ≥ 5` to prevent collapse. `Pressure > 0.0` only on closed meshes.

In Godot 4.6, `apply_central_impulse()` and `apply_central_force()` distribute force across all `SoftBody3D` simulation points.

> See [references/softbody-recipes.md](references/softbody-recipes.md) for the cloth/cape walkthrough and supported GDScript force/impulse examples.

---

## 13. Troubleshooting Physics Issues

Symptom → causes & fixes quick table covering tunneling, wobbly stacks, scaled shapes, tile collision bumps, unstable cylinders, the physics spiral of death, and float-precision issues far from origin.

> See [references/troubleshooting.md](references/troubleshooting.md) for the full table.

---

## 14. Implementation Checklist

- [ ] Dynamic bodies use primitive collision shapes; concave shapes only on StaticBodies
- [ ] Collision layers named in Project Settings; layer/mask set correctly per body
- [ ] No `scale` on collision shapes or bodies — use shape size parameters directly
- [ ] RigidBodies modify state via `_integrate_forces()`, not `_physics_process()`
- [ ] RigidBodies needing contact signals set `contact_monitor = true` + `max_contacts_reported > 0`
- [ ] Moving platforms use `AnimatableBody2D/3D` (not manually moved StaticBody)
- [ ] Code raycasts use `PhysicsDirectSpaceState` inside `_physics_process()` only
- [ ] Physics interpolation enabled; `reset_physics_interpolation()` called after teleport / initial placement
- [ ] Ragdoll bones on a separate collision layer from the character capsule
- [ ] 3D projects use the Godot 4.6 Jolt default unless project constraints require GodotPhysics

---
name: godot-optimization
description: Use when profiling and optimizing Godot 4.6 GDScript Web projects through measured frame, rendering, physics, allocation, and memory evidence
---

# Godot Optimization for Builda Web

Optimize only after reproducing a measurable problem on the target scene and Web profile. Builda defaults to Godot 4.6.x, GDScript, Compatibility rendering, and a single-threaded Web export; moving work to threads is not a default remedy.

## 1. Define the Performance Contract

Record the target device/browser, scene, resolution, target FPS, warm-up duration, and interaction sequence. Convert the target FPS into a frame-time budget, but judge success by captured measurements rather than generic object or draw-call counts.

| Target FPS | Total frame budget |
|---|---|
| 120 | 8.3 ms |
| 60 | 16.6 ms |
| 30 | 33.3 ms |

The total budget includes script, physics, rendering, browser overhead, and stalls. A subsystem budget must be derived from the project target, not copied from a universal threshold.

## 2. Measure Before Changing Code

Use the Godot Profiler and Monitors when an editor is available. For terminal/headless reproduction, add a bounded measurement around the suspected operation:

```gdscript
var started_usec := Time.get_ticks_usec()
run_suspected_operation()
var elapsed_usec := Time.get_ticks_usec() - started_usec
print_debug("operation_usec=%d" % elapsed_usec)
```

Capture at least:

- baseline frame time and worst spikes for the same scenario;
- script self time and call count;
- physics time and active object counts;
- draw calls, material changes, and visible item counts;
- memory/object count before and after repeated scene transitions.

Change one suspected cause, rerun the identical scenario, and keep the change only if the relevant metric and observed behavior improve.

## 3. CPU and GDScript Hot Paths

Start with the profiler's highest self-time functions. Common fixes include:

- cache stable node/group lookups instead of repeating them each frame;
- avoid constructing Arrays, Dictionaries, and formatted Strings in hot loops;
- use typed data and `StringName` for frequently compared identifiers;
- throttle expensive target/path/visibility updates that do not need every frame;
- preload stable resources instead of loading them during gameplay;
- disable processing on inactive/off-screen systems when lifecycle semantics allow it.

Do not move gameplay logic from `_process()` to `_physics_process()` merely because physics ticks are often lower; choose the callback required by behavior and throttle explicitly. See [references/cpu-bottlenecks.md](references/cpu-bottlenecks.md).

## 4. Rendering and Draw Calls

Draw-call cost varies by browser, GPU, resolution, overdraw, materials, and shader complexity. Establish a baseline on the target Web device and optimize the dominant rendering cost.

Useful levers:

- share textures/materials when visual behavior permits;
- atlas compatible sprites;
- reduce transparent overdraw and oversized textures;
- cull work that is genuinely outside the visible region;
- reduce material/shader variants that break batching;
- use mesh/LOD changes only after profiling shows geometry cost.

`CanvasGroup` is not a universal batching rule. It renders children through an intermediate group buffer for group compositing and can add fill-rate or framebuffer cost. Use it only when the visual grouping semantics are required or a target-device measurement proves a gain; compare before/after draw calls and frame time.

See [references/draw-calls.md](references/draw-calls.md) for mechanisms and constraints.

## 5. Physics

Measure physics time before changing tick rate or collision behavior. Then:

- narrow collision layers and masks;
- use simple shapes for moving bodies;
- allow eligible rigid bodies to sleep;
- avoid repeated broad queries when an `Area2D/3D` event can express the same contract;
- update expensive queries at the minimum cadence required by gameplay.

Changing `Engine.physics_ticks_per_second` changes simulation behavior and must be validated for movement, collision, input, and determinism. See [references/physics-tuning.md](references/physics-tuning.md).

## 6. Memory and Lifecycle

Compare object/memory counts after repeated enter/exit cycles, not at one instant. Growing counts can indicate retained signals, autoload references, cached resources, or nodes never released.

- use `queue_free()` for normal node teardown;
- disconnect or scope long-lived signal ownership;
- duplicate shared resources only when per-instance mutation is intended;
- pool only high-frequency objects whose allocation/teardown is measured as a bottleneck;
- reset every piece of pooled state, including signals, timers, visibility, and velocity.

Pooling is not automatically faster and increases lifecycle complexity. See [references/memory-management.md](references/memory-management.md).

## 7. Verification

For each accepted change record:

1. baseline metric and capture scenario;
2. changed code or asset setting;
3. after metric from the identical scenario;
4. visual/gameplay regression result;
5. Web target and browser used.

Headless timing is useful for script/logic regressions but does not represent browser rendering performance. Rendering changes require Web-preview or exported-Web measurement.

## Checklist

- [ ] Target scene, device/browser, resolution, FPS, and reproduction sequence are explicit.
- [ ] Baseline and after measurements use the same scenario.
- [ ] Optimization addresses a measured hotspot rather than a generic threshold.
- [ ] No threaded remedy is assumed for the single-thread Web profile.
- [ ] `CanvasGroup` is used for required compositing or evidence-backed benefit, not unconditionally.
- [ ] Physics changes are checked for behavior and determinism regressions.
- [ ] Memory is compared across repeated lifecycle cycles.
- [ ] Pooling is introduced only for a measured allocation/teardown bottleneck.
- [ ] Rendering changes are validated in Web, not inferred from headless success.

---
name: camera-system
description: Implement or review Camera2D and Camera3D behavior in Godot 4.6.x GDScript for Builda's single-threaded Web runtime. Use for follow, smoothing, limits, look-ahead, shake, zoom, transitions, camera zones, and target handoff with frame-rate-safe interpolation.
---

# Camera System

Target Godot 4.6.x, GDScript, single-threaded Web, and the Compatibility renderer.

## Ownership

Keep one active camera owner per viewport. Gameplay systems expose targets or camera requests; they should not compete by writing the camera transform directly.

Use built-in `Camera2D` position smoothing and limits when they express the desired behavior. Use custom smoothing when you need target handoff, look-ahead, or explicit damping.

## Frame-rate-safe smoothing

Never pass an unclamped `speed * delta` directly to `lerp()` or `Vector*.lerp()`: frame spikes can produce a weight above `1.0` and overshoot.

Linear clamped weight:

```gdscript
@export_range(0.0, 30.0, 0.1) var follow_speed: float = 8.0
@export var target: Node2D

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var weight := clampf(follow_speed * delta, 0.0, 1.0)
    global_position = global_position.lerp(target.global_position, weight)
```

For damping that is more consistent across frame rates, use an exponential weight and still clamp it:

```gdscript
var weight := clampf(1.0 - exp(-follow_speed * delta), 0.0, 1.0)
global_position = global_position.lerp(target.global_position, weight)
```

Apply the same rule to zoom, offset, and 3D transforms. Use quaternion interpolation for rotation rather than lerping Euler angles across wrap boundaries.

## Camera2D

- Use `limit_left/right/top/bottom` for world bounds.
- Remember that `global_position` may differ from the actual screen center while built-in smoothing or offsets apply; query the screen-center API when product logic needs the rendered center.
- Keep look-ahead bounded and return it smoothly to zero.
- Call `reset_smoothing()` after teleports or discontinuous room changes.
- Do not put gameplay collision or authority on camera position.

## Camera3D

Follow a dedicated pivot/rig rather than mixing orbit, collision, and shake directly on the camera node. Typical hierarchy:

```text
CameraRig (Node3D)       # follow position
└── YawPivot (Node3D)    # horizontal orbit
    └── PitchPivot       # vertical orbit
        └── Camera3D     # distance and local shake
```

Clamp pitch before constructing the transform. For obstruction handling, raycast or shape-cast from the pivot toward the desired camera point, then smooth the resolved distance independently from target follow.

## Shake

Apply shake as a bounded local offset after base follow/limits have been resolved. Use time-based decay and deterministic noise when reproducibility matters. Do not accumulate random offsets into the authoritative base transform.

```gdscript
var _shake_strength: float = 0.0

func add_shake(amount: float) -> void:
    _shake_strength = maxf(_shake_strength, amount)

func _process(delta: float) -> void:
    _update_follow(delta)
    offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
    _shake_strength = move_toward(_shake_strength, 0.0, 20.0 * delta)
```

## Transitions and target handoff

Store one transition token or Tween. Replace or kill it before starting another transition. When awaiting completion, verify the request is still current and the camera remains in the tree.

For room/zone cameras, let the zone request a profile (limits, zoom, follow target), while the camera owner applies it. Define overlap priority so entering two zones cannot cause flicker.

## Web checks

- Resize the browser and verify aspect-dependent framing.
- Test frame spikes to ensure interpolation cannot overshoot.
- Test target deletion, scene changes, and teleports.
- Test paused and background-tab resume behavior.
- Verify Camera3D effects only use Compatibility-supported rendering.

## References boundary

No bundled reference is required by default. Existing `references/` files are optional legacy material and may contain other language or lifecycle models. Do not load them automatically; adapt only verified target-version GDScript when an explicit request requires it.

## Checklist

- [ ] One owner writes the active camera transform.
- [ ] Every interpolation weight is clamped to `[0, 1]`.
- [ ] Teleports reset smoothing.
- [ ] Look-ahead, shake, and collision offsets do not corrupt base follow state.
- [ ] Zone overlap and transition replacement are deterministic.
- [ ] Target deletion and scene exit are safe.
- [ ] Browser resize and frame-spike behavior are tested.

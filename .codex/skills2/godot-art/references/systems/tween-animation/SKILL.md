---
name: tween-animation
description: Implement or review Godot 4.6.x Tweens in GDScript for Builda's single-threaded Web runtime. Use for property and method tweening, callbacks, intervals, easing, sequential and parallel composition, loops, pause behavior, replacement, and cancellation-safe UI or gameplay motion.
---

# Tween Animation

Target Godot 4.6.x and GDScript.

## Choose Tween versus AnimationPlayer

Use Tween for short procedural motion whose start/end values are known at runtime: fades, panel slides, feedback pulses, counters, and one-off transforms. Use AnimationPlayer for authored multi-track clips and reusable timelines.

## Create and store Tweens

`create_tween()` creates a new SceneTree Tween. It does not replace another Tween affecting the same property. Store the active Tween when later requests may compete.

```gdscript
var _move_tween: Tween

func move_to(target: Vector2) -> void:
    if _move_tween != null and _move_tween.is_valid():
        _move_tween.kill()
    _move_tween = create_tween()
    _move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _move_tween.tween_property(self, "position", target, 0.4)
```

After a Tween finishes, do not append new tweeners to it. Create a new Tween for the next sequence.

## Tweener types

```gdscript
var tween := create_tween()
tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.25)
tween.tween_interval(0.1)
tween.tween_callback(_on_hidden)
```

Use `tween_method()` when interpolation feeds a typed setter:

```gdscript
func animate_score(from_value: float, to_value: float) -> void:
    create_tween().tween_method(_set_score_display, from_value, to_value, 0.5)

func _set_score_display(value: float) -> void:
    %ScoreLabel.text = str(roundi(value))
```

Property subcomponents use paths such as `"position:x"` and `"modulate:a"`.

## Sequential and parallel composition

Tweeners are sequential by default.

```gdscript
var tween := create_tween()
tween.tween_property(self, "position:x", 300.0, 0.3)
tween.tween_property(self, "position:y", 200.0, 0.3)
```

Use `parallel()` for a tweener that shares the current step, or `set_parallel(true)` for a parallel section. Use `chain()` to return to a following sequential step.

```gdscript
var tween := create_tween().set_parallel(true)
tween.tween_property(self, "position", Vector2(300, 200), 0.4)
tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.4)
tween.chain().tween_property(self, "modulate:a", 0.0, 0.2)
```

Add callbacks after `chain()` when they must wait for all parallel motion.

## Easing and modifiers

Set an intentional transition/ease for visible motion. `TRANS_CUBIC` with `EASE_OUT` is a useful neutral default, but product feel decides.

Use the returned `PropertyTweener` for modifiers:

```gdscript
var tweener := create_tween().tween_property(self, "scale", Vector2.ONE, 0.25)
tweener.from(Vector2.ZERO).set_delay(0.05)
```

Use relative motion only for one-shot offsets whose accumulation is intentional. Prefer absolute endpoints for looping animation.

## Dynamic sequence construction

Godot 4.6 does not need an inspection API to decide whether a dynamic sequence is empty. Track whether a step was appended:

```gdscript
var tween := create_tween()
var added_step := false

if should_fade:
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    added_step = true

if not added_step:
    tween.kill()
```

## Completion and lifecycle

Do not `await tween.finished` on a Tween that another request may `kill()`: a killed Tween does not complete normally, so the suspended caller may never resume. Put replacement-safe completion in a guarded callback instead:

```gdscript
func start_transition(target: Vector2) -> void:
    _transition_generation += 1
    var generation := _transition_generation
    if _move_tween != null and _move_tween.is_valid():
        _move_tween.kill()

    _move_tween = create_tween()
    _move_tween.tween_property(self, "position", target, 0.3)
    _move_tween.tween_callback(func() -> void:
        if generation == _transition_generation and is_inside_tree():
            _finish_transition()
    )
```

Await `finished` only when ownership guarantees that the Tween cannot be killed or abandoned. If an API must itself be awaitable and replaceable, expose a separate completion result that the owner resolves on both normal finish and cancellation.

Set pause mode and ignore-time-scale behavior explicitly for UI, pause menus, and slow motion. Infinite loops must always contain nonzero-duration work.

## Web checks

- Trigger replacement repeatedly and verify no competing Tweens remain.
- Test pause, time scale, hidden-tab resume, and scene exit.
- Avoid spawning unbounded Tweens in per-frame callbacks.
- Verify UI layout after browser resize before tweening absolute positions.

## References boundary

No bundled reference is required by default. Existing `references/` files are optional legacy recipes and may contain other language or version-era APIs. Do not load them automatically; use only verified target-version GDScript fragments when explicitly needed.

## Checklist

- [ ] Competing Tweens are killed or replaced by one owner.
- [ ] Parallel sections return to sequential order before dependent callbacks.
- [ ] Dynamic builders track whether they added a step.
- [ ] Replaceable Tweens do not leave a caller suspended on `finished`.
- [ ] Pause and time-scale semantics are explicit.
- [ ] Loops contain nonzero-duration work.
- [ ] Browser resize and lifecycle behavior are verified.

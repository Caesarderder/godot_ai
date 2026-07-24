# PropertyTweener Modifiers

Reference for `skills/tween-animation/SKILL.md` — `from()`, `from_current()`, `as_relative()`, `set_delay()` for per-tweener customization.

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. PropertyTweener Modifiers

### from() — Set custom start value

```gdscript
# Slide in from off-screen (starts at x=-200, animates to current position)
var tween := create_tween()
tween.tween_property($Panel, "position:x", $Panel.position.x, 0.4) \
    .from(-200.0)
```


### from_current() — Capture current value as start

```gdscript
# Ensure tween starts from wherever the property is right now
tween.tween_property(self, "position", target_pos, 0.5).from_current()
```


### as_relative() — Final value is added to current

```gdscript
# Move 100 pixels right from wherever the node currently is
tween.tween_property(self, "position:x", 100.0, 0.3).as_relative()
```


### set_delay() — Delay before this tweener starts

```gdscript
var tween := create_tween().set_parallel(true)
tween.tween_property($Label1, "modulate:a", 1.0, 0.3).from(0.0)
tween.tween_property($Label2, "modulate:a", 1.0, 0.3).from(0.0).set_delay(0.1)
tween.tween_property($Label3, "modulate:a", 1.0, 0.3).from(0.0).set_delay(0.2)
# Staggered fade-in: Label1, then Label2, then Label3
```

---

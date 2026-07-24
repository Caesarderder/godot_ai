# Looping and Signals

Reference for `skills/tween-animation/SKILL.md` — `set_loops()`, `finished` / `step_finished` / `loop_finished` signals.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Looping & Signals

### Looping

```gdscript
# Loop forever (0 = infinite)
var tween := create_tween().set_loops()
tween.tween_property($Icon, "rotation", TAU, 2.0).as_relative()

# Loop 3 times
var tween2 := create_tween().set_loops(3)
tween2.tween_property($Sprite, "modulate:a", 0.3, 0.5)
tween2.tween_property($Sprite, "modulate:a", 1.0, 0.5)
```


### Signals

```gdscript
var tween := create_tween()
tween.tween_property(self, "position", Vector2(300, 200), 0.5)
tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
    print("Tween complete!")
```


| Signal                       | Fires When                                   |
|------------------------------|----------------------------------------------|
| `finished`                   | All tweeners complete (after final loop)     |
| `loop_finished(loop_count)`  | Each loop iteration completes                |
| `step_finished(idx)`         | Each individual tweener completes            |

---

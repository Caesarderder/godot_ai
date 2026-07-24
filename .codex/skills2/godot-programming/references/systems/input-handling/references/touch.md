# Touch Input

Reference for `skills/input-handling/SKILL.md` — basic touch events and emulate-touch-from-mouse.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Touch Input

### Basic Touch Events

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            print("Touch at: ", event.position)
        else:
            print("Touch released")

    if event is InputEventScreenDrag:
        print("Drag delta: ", event.relative)
```


### Emulate Touch from Mouse

Enable in **Project > Project Settings > Input Devices > Pointing > Emulate Touch From Mouse**. This lets you test touch input on desktop with mouse clicks.

The reverse (**Emulate Mouse From Touch**) is enabled by default — touchscreen taps generate mouse events so UI controls work on mobile without changes.

---

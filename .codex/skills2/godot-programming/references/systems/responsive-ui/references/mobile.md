# Mobile Considerations

Reference for `skills/responsive-ui/SKILL.md` — touch input, safe-area insets (notch / dynamic island), orientation lock, virtual keyboard handling.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Mobile Considerations

### Touch Input

**GDScript:**

```gdscript
extends Node

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _on_touch_begin(event.position, event.index)
        else:
            _on_touch_end(event.position, event.index)
    elif event is InputEventScreenDrag:
        _on_touch_drag(event.position, event.relative, event.index)


func _on_touch_begin(pos: Vector2, finger: int) -> void:
    pass  # handle tap / press

func _on_touch_end(pos: Vector2, finger: int) -> void:
    pass

func _on_touch_drag(pos: Vector2, delta: Vector2, finger: int) -> void:
    pass  # handle swipe / scroll
```



### Safe Area Insets

Native fullscreen mobile exports can report a safe-area rectangle in physical screen coordinates. Convert those pixel insets into the viewport's logical UI coordinates before applying them to a `MarginContainer`. Builda Web projects cannot treat this API as browser CSS safe-area data; the host page/canvas owns that inset.

**GDScript:**

```gdscript
func _ready() -> void:
    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    var screen_size: Vector2i = DisplayServer.screen_get_size()

    # Safe area and screen size are physical screen pixels. MarginContainer
    # constants use the stretched viewport's logical UI units.
    var ui_size := get_viewport().get_visible_rect().size
    var screen_to_ui := ui_size / Vector2(screen_size)
    var inset_left   := roundi(safe_area.position.x * screen_to_ui.x)
    var inset_top    := roundi(safe_area.position.y * screen_to_ui.y)
    var inset_right  := roundi((screen_size.x - safe_area.end.x) * screen_to_ui.x)
    var inset_bottom := roundi((screen_size.y - safe_area.end.y) * screen_to_ui.y)

    # Apply to a MarginContainer wrapping all HUD content
    $SafeAreaMargin.add_theme_constant_override("margin_left",   inset_left)
    $SafeAreaMargin.add_theme_constant_override("margin_top",    inset_top)
    $SafeAreaMargin.add_theme_constant_override("margin_right",  inset_right)
    $SafeAreaMargin.add_theme_constant_override("margin_bottom", inset_bottom)
```



### Orientation Lock

In `Project > Project Settings > Display > Window`:

- `Handheld > Orientation` → `landscape`, `portrait`, `reverse_landscape`, `sensor`, etc.

Or at runtime:

**GDScript:**

```gdscript
# Lock to landscape
DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

# Lock to portrait
DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

# Follow device sensor
DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
```



### Virtual Keyboard

**GDScript:**

```gdscript
# Show keyboard (call after focusing a LineEdit, or manually)
DisplayServer.virtual_keyboard_show("initial text")

# Hide keyboard
DisplayServer.virtual_keyboard_hide()

# Query keyboard height to shift UI above it
var kb_height: int = DisplayServer.virtual_keyboard_get_height()
```



> **Note:** `LineEdit` and `TextEdit` show/hide the virtual keyboard automatically when they gain and lose focus. Call the API manually only when building custom text input widgets.

---

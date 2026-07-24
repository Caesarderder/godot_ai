# Custom Drawing

Reference for `skills/2d-essentials/SKILL.md` — `_draw()` method, redrawing patterns, full drawing methods reference, default font usage, editor preview with `@tool`, line-width tip.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Custom Drawing

### The _draw() Method

Override `_draw()` on any `CanvasItem`-derived node (Node2D or Control) for custom rendering.

```gdscript
extends Node2D

func _draw() -> void:
    draw_circle(Vector2.ZERO, 50.0, Color.RED)
    draw_rect(Rect2(-25, -25, 50, 50), Color.BLUE, false, 2.0)
    draw_line(Vector2(-100, 0), Vector2(100, 0), Color.WHITE, 2.0, true)
```

### Redrawing

`_draw()` is called once and cached. Call `queue_redraw()` to trigger a redraw.

```gdscript
@export var radius: float = 50.0:
    set(value):
        radius = value
        queue_redraw()  # Redraw when property changes

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, Color.RED)
```

For per-frame animation, call `queue_redraw()` from `_process()`.

### Drawing Methods Reference

| Method | Description |
|--------|-------------|
| `draw_line(from, to, color, width, antialiased)` | Single line segment |
| `draw_multiline(points, color, width)` | Multiple disconnected lines (better performance) |
| `draw_polyline(points, color, width, antialiased)` | Connected line sequence |
| `draw_polygon(points, colors)` | Filled polygon (auto-closes) |
| `draw_circle(center, radius, color)` | Filled circle |
| `draw_arc(center, radius, start, end, segments, color, width, aa)` | Arc / partial circle |
| `draw_rect(rect, color, filled, width)` | Rectangle (filled or outline) |
| `draw_texture(texture, position)` | Draw a texture |
| `draw_string(font, position, text, alignment, width, font_size)` | Draw text |
| `draw_set_transform(position, rotation, scale)` | Apply transform for subsequent draws (rotation/scale optional) |

### Default Font

```gdscript
var font: Font = ThemeDB.fallback_font

func _draw() -> void:
    draw_string(font, Vector2(10, 30), "Score: 100", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
```

### Editor Preview with @tool

Add `@tool` to see custom drawing in the editor. Requires a scene reload after adding or removing the annotation. This editor-only path is outside the default runtime workflow; use it only when an editor preview is explicitly required.

### Line Width Tip

Odd-width lines (1px, 3px): offset start/end positions by `0.5` to center the line on a pixel boundary and avoid subpixel blurriness.

---

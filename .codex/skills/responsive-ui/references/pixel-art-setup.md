# Pixel Art Setup

Reference for `skills/responsive-ui/SKILL.md` — project settings for pixel art, integer scaling via script, nearest-neighbour filter overrides.

> ← Back to [SKILL.md](../SKILL.md)

---
## 4. Pixel Art Setup

### Project Settings

In `Project > Project Settings`:

- `Display > Window > Stretch > Mode` → `viewport`
- `Display > Window > Stretch > Scale` → `1`
- `Display > Window > Stretch > Scale Mode` → `integer`
- `Rendering > Textures > Canvas Textures > Default Texture Filter` → `Nearest`

Setting the texture filter to `Nearest` globally avoids blurry pixels without per-sprite configuration.

### Integer Scaling via Script

**GDScript:**

```gdscript
# res://autoload/display_manager.gd
extends Node

const BASE_SIZE := Vector2i(320, 180)  # pixel art design resolution

func _ready() -> void:
    get_window().content_scale_size = BASE_SIZE
    get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
    get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
    get_window().content_scale_factor = 1.0
    get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
```



### Nearest-Neighbour Filter per Node (Override)

If the global filter is `Linear` and you only want `Nearest` on specific sprites:

**GDScript:**

```gdscript
# On a Sprite2D or TextureRect node
$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```



---

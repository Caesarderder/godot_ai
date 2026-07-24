# DPI Scaling

Reference for `skills/responsive-ui/SKILL.md` — `content_scale_factor`, querying DPI at runtime for retina/high-DPI handling.

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. DPI Scaling

### content_scale_factor

`Window.content_scale_factor` multiplies UI sizes uniformly. The DPI-query recipe below is optional for native desktop/mobile exports. In Builda Web exports, `screen_get_dpi()` does not describe the browser's CSS/device-pixel mapping reliably; keep responsive layout in viewport coordinates and let the host canvas handle device-pixel scaling.

**GDScript:**

```gdscript
# autoload/dpi_scaler.gd
extends Node

func _ready() -> void:
    _apply_dpi_scale()


func _apply_dpi_scale() -> void:
    var dpi := DisplayServer.screen_get_dpi()
    # 96 dpi is the standard desktop reference
    var scale := clampf(dpi / 96.0, 1.0, 3.0)
    # Round to nearest 0.25 to avoid blurry half-pixel rendering
    scale = roundf(scale * 4.0) / 4.0
    get_window().content_scale_factor = scale


func get_dpi() -> int:
    return DisplayServer.screen_get_dpi()
```



### Querying DPI at Runtime

**GDScript:**

```gdscript
var dpi: int = DisplayServer.screen_get_dpi()
print("Screen DPI: %d" % dpi)  # 96 on standard, 192+ on Retina
```



> **Native-only note:** Verify reported DPI on each target OS; do not hard-code these values as a Web capability check.

---

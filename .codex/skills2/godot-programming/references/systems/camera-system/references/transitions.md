# Camera Transitions

Reference for `skills/camera-system/SKILL.md` — async camera transitions for 2D and 3D using Tween + ToSignal.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Camera Transitions

To cut or blend between two cameras (e.g. entering a cutscene, switching player perspective), tween the active camera's position and zoom/FOV toward the second camera's values, then make the switch.

### GDScript

```gdscript
## CameraTransitionManager.gd — Autoload or attach to a scene manager node
extends Node

## Transition the active Camera2D to match the position and zoom of `next_cam`
## over `duration` seconds, then make `next_cam` the active camera.
func transition_2d(next_cam: Camera2D, duration: float = 0.5) -> void:
    var viewport := get_viewport()
    var current_cam := viewport.get_camera_2d()
    if not current_cam or current_cam == next_cam:
        return

    # Temporarily make the current camera a top-level node so it doesn't follow its parent
    current_cam.top_level = true

    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)

    tween.tween_property(current_cam, "global_position", next_cam.global_position, duration)
    tween.tween_property(current_cam, "zoom", next_cam.zoom, duration)

    await tween.finished

    # Hand off — make the destination camera active and restore state
    next_cam.make_current()
    current_cam.top_level = false

## Transition between two Camera3D nodes (blends position and FOV)
func transition_3d(next_cam: Camera3D, duration: float = 0.5) -> void:
    var current_cam := get_viewport().get_camera_3d()
    if not current_cam or current_cam == next_cam:
        return

    current_cam.top_level = true

    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)

    tween.tween_property(current_cam, "global_position", next_cam.global_position, duration)
    tween.tween_property(current_cam, "global_rotation", next_cam.global_rotation, duration)
    tween.tween_property(current_cam, "fov", next_cam.fov, duration)

    await tween.finished

    next_cam.make_current()
    current_cam.top_level = false
```

**Usage:**

```gdscript
# From anywhere that can reach the manager
CameraTransitionManager.transition_2d($CutsceneCam, 0.6)
```

---

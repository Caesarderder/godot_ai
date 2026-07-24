# Surface Marks in Compatibility

Reference for `skills/3d-essentials/SKILL.md` — renderer-safe substitutes for projected decals.

> ← Back to [SKILL.md](../SKILL.md)

---
## 7. Surface Marks

The Builda Web target uses the Compatibility renderer, so do not depend on the `Decal` rendering pipeline. Use authored geometry, a small transparent quad, a particle burst, or a texture change on the affected mesh. Keep the effect count bounded to avoid transparent overdraw.

### Scene Setup

```
World
├── MeshInstance3D (floor)
└── SurfaceMarks (Node3D)
    └── MeshInstance3D (small QuadMesh + transparent material)
```

### Spawning a Bounded Mark

#### GDScript

```gdscript
@export var mark_scene: PackedScene
@export_range(1, 128, 1) var max_marks: int = 32

var _marks: Array[Node3D] = []

func spawn_surface_mark(hit_pos: Vector3, hit_normal: Vector3) -> void:
    if mark_scene == null or hit_normal.is_zero_approx():
        return

    var mark := mark_scene.instantiate() as Node3D
    if mark == null:
        return
    $SurfaceMarks.add_child(mark)
    mark.global_position = hit_pos + hit_normal.normalized() * 0.002
    mark.look_at(mark.global_position + hit_normal, Vector3.UP)
    _marks.append(mark)

    if _marks.size() > max_marks:
        var oldest := _marks.pop_front()
        if is_instance_valid(oldest):
            oldest.queue_free()
```

Use a material configured and verified in the Compatibility renderer. Offset marks slightly from the surface to avoid z-fighting, and pool them if creation shows up in a Web profile.

---

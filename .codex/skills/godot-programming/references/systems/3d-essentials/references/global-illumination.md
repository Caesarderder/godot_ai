# Global Illumination

Reference for `skills/3d-essentials/SKILL.md` — Compatibility-safe ambient and reflection lighting.

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. Global Illumination

### GI Methods Comparison

| Method          | Quality   | Performance | Dynamic | Renderer  | Use For                    |
|-----------------|-----------|-------------|---------|-----------|----------------------------|
| None (ambient)  | Low       | Free        | Yes     | All       | Simple/stylized games      |
| `ReflectionProbe` | Medium  | Low         | Optional | All      | Localized reflections      |

### ReflectionProbe

Captures the surrounding environment into a cubemap for reflections on nearby objects.

```
Room (Node3D)
├── ReflectionProbe      ← extents cover the room
├── MeshInstance3D (walls)
└── MeshInstance3D (shiny floor)
```

```gdscript
@onready var probe: ReflectionProbe = $ReflectionProbe

func _ready() -> void:
    probe.size = Vector3(10.0, 4.0, 10.0)  # cover the room
    probe.update_mode = ReflectionProbe.UPDATE_ONCE  # bake once, free at runtime
```

Keep indirect lighting simple for Compatibility Web: tune the Environment's ambient source, a sky, restrained direct lights, and reflection probes. Do not route this target to `LightmapGI`, `VoxelGI`, or `SDFGI` recipes without first changing and validating the renderer contract.

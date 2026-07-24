# Materials & Lighting Recipes

Reference for `skills/3d-essentials/SKILL.md` — runnable code recipes for creating materials at runtime, per-instance material copies, dynamic lights with tween-driven decay, light properties, shadow configuration, and bake modes.

> ← Back to [SKILL.md](../SKILL.md)

---

## Setting Materials from Code

### GDScript

```gdscript
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.2, 0.2)
    mat.metallic = 0.3
    mat.roughness = 0.7
    mesh.material_override = mat

func flash_emissive() -> void:
    var mat: StandardMaterial3D = mesh.material_override
    mat.emission_enabled = true
    mat.emission = Color.WHITE
    mat.emission_energy_multiplier = 3.0
    var tween := create_tween()
    tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.3)
    tween.tween_callback(func(): mat.emission_enabled = false)
```

## Transparency Modes

| Mode                | Performance | Shadows | Use For                          |
|---------------------|-------------|---------|----------------------------------|
| Disabled            | Fastest     | Yes     | Fully opaque objects             |
| Alpha               | Slow        | No      | Semi-transparent glass, water    |
| Alpha Scissor       | Fast        | Yes     | Binary cutout (leaves, fences)   |
| Alpha Hash          | Medium      | Yes     | Dithered transparency (hair)     |
| Depth Pre-Pass      | Medium      | Partial | Mostly opaque with transparent edges |

## Material Instancing

When multiple `MeshInstance3D` nodes share the same material, changing one affects all. To make a per-instance copy:

```gdscript
# In _ready() — creates an independent copy of the material
mesh.material_override = mesh.material_override.duplicate()
```

## Light Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `light_color` | `Color` | white | Drive day/night with a Tween or `Environment.sun_position` |
| `light_energy` | `float` | 1.0 | HDR; values >1 are valid |
| `shadow_enabled` | `bool` | false | Big perf hit when enabled |
| `directional_shadow_mode` | enum | 4 splits | `ORTHOGONAL` / `PARALLEL_2_SPLITS` / `PARALLEL_4_SPLITS` |
| `directional_shadow_max_distance` | `float` | 100 m | Lower = sharper shadows |

```gdscript
sun.light_color = Color(1.0, 0.95, 0.9)
sun.shadow_enabled = true
sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
sun.directional_shadow_max_distance = 100.0
```

## Shadow Configuration Tips

| Setting                     | Effect                                             | Recommendation                       |
|-----------------------------|-----------------------------------------------------|--------------------------------------|
| `shadow_bias`               | Prevents self-shadowing (shadow acne)               | Start at 0.1, increase if acne visible |
| `shadow_normal_bias`        | Better acne fix than regular bias                   | Prefer this over `shadow_bias`       |
| `directional_shadow_max_distance` | Limits shadow range from camera               | Lower = better quality; 50–100m typical |
| Shadow map resolution       | Project Settings > Rendering > Lights and Shadows  | 2048 for perf, 4096 for quality      |
| `shadow_blur`               | Softens shadow edges                                | 1.0–2.0 for gentle softness         |

## Light Bake Modes

| Mode     | Description                                               | Use For                             |
|----------|-----------------------------------------------------------|-------------------------------------|
| Disabled | Not included in lightmap baking; fully real-time (default) | Moving lights, player flashlight    |
| Static   | Fully baked into lightmaps — no runtime cost              | Architecture, terrain, fixed lights |
| Dynamic  | Indirect light baked, direct light stays real-time        | Lights that change color/intensity  |

## Dynamic Point Light

Spawn an OmniLight3D at runtime, drive its energy with a tween, and queue-free it on tween completion. Pattern works for explosions, muzzle flashes, magic effects.

```gdscript
func create_explosion_light(pos: Vector3) -> void:
    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.6, 0.2)
    light.light_energy = 4.0
    light.omni_range = 10.0
    light.omni_attenuation = 2.0
    light.position = pos
    add_child(light)

    var tween := create_tween()
    tween.tween_property(light, "light_energy", 0.0, 0.5)
    tween.tween_callback(light.queue_free)
```

## Bent Normal Maps (Godot 4.5+)

Code path for setting a bent-normal texture at runtime (the typical case is via Inspector instead).

```gdscript
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
    var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
    if mat == null:
        mat = StandardMaterial3D.new()
    mat.bent_normal_enabled = true
    mat.bent_normal_texture = preload("res://textures/rock_bent_normal.png")
    mesh.set_surface_override_material(0, mat)
```

# Environment & Post-Processing

Reference for `skills/3d-essentials/SKILL.md` — Compatibility-safe `WorldEnvironment`, sky, tonemap, fog, glow, and color adjustments.

> ← Back to [SKILL.md](../SKILL.md)

---
## 4. Environment & Post-Processing

### WorldEnvironment Setup

```
World (Node3D)
├── WorldEnvironment     ← holds Environment + CameraAttributes resources
├── DirectionalLight3D
├── Camera3D
└── ...
```

Set the **Environment** resource on WorldEnvironment and the **Camera Attributes** for exposure/DOF.

### Sky Options

| Sky Material           | Description                              | Use For                    |
|------------------------|------------------------------------------|----------------------------|
| `PanoramaSkyMaterial`  | 360° HDR panorama image                 | Realistic environments     |
| `ProceduralSkyMaterial` | Generated sky with color gradients     | Quick prototyping          |
| `PhysicalSkyMaterial`  | Physics-based atmosphere + sun          | Outdoor day/night cycles   |

#### GDScript

```gdscript
func setup_environment() -> void:
    var env := Environment.new()

    # Sky
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.4, 0.6, 1.0)
    sky_mat.sky_horizon_color = Color(0.7, 0.8, 1.0)
    sky_mat.ground_bottom_color = Color(0.2, 0.15, 0.1)
    sky.sky_material = sky_mat
    env.sky = sky
    env.background_mode = Environment.BG_SKY

    # Tonemap
    env.tonemap_mode = Environment.TONE_MAP_FILMIC
    env.tonemap_exposure = 1.0

    # Ambient light from sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

    $WorldEnvironment.environment = env
```

### Tonemap Modes

| Mode       | Character                                  | Best For                       |
|------------|---------------------------------------------|--------------------------------|
| Linear     | Clips brights — blown-out look             | Debug, deliberately flat look  |
| Reinhard   | Simple curve, preserves brights            | General use                    |
| Filmic     | Film-like contrast                          | Cinematic games                |
| ACES       | High contrast with desaturation            | Realistic/photographic         |
| AgX        | Maintains hue as brightness increases      | Physically accurate lighting   |

### Post-Processing Effects (Inspector)

Configure only effects supported by the Compatibility renderer, and validate them in the exported Web build:

| Effect    | Description                              | Renderer Support         |
|-----------|------------------------------------------|--------------------------|
| Glow | Bloom/glow on bright surfaces |
| Fog | Depth and height fog |
| Adjustments | Brightness, contrast, saturation, color correction |

### Glow Pipeline and AgX Controls (Godot 4.6+)

Godot 4.6 changes the order of the post-processing pipeline: **Glow now runs before tonemapping** (previously it ran after). This is physically more correct — glow should operate on HDR values before they are tone-mapped to LDR. The result is that bright emissive surfaces produce more natural-looking bloom.

**Upgrade impact:** Projects upgrading from 4.5 to 4.6 may notice a visible change in glow appearance. If your glow looks more intense or differently colored after upgrading, re-tune `glow_intensity`, `glow_bloom`, and `glow_hdr_threshold` on your Environment resource.

Godot 4.6 also adds two new controls to the **AgX** tonemapper:

| Property | Description |
|----------|-------------|
| `tonemap_white` | White point — the luminance at which the scene clips to pure white |
| `tonemap_contrast` | Contrast of the AgX sigmoid curve |

```gdscript
var env: Environment = $WorldEnvironment.environment
env.tonemap_mode = Environment.TONE_MAP_AGX
# New AgX controls (Godot 4.6+)
env.tonemap_white = 1.0       # default; increase for brighter highlights
env.tonemap_contrast = 1.0    # default; increase for more contrast
```

> **When to use AgX:** AgX maintains hue as brightness increases, which avoids the "neon burn" artefact common with ACES on saturated emissives. The new `white` and `contrast` controls let you match a specific look reference.

---

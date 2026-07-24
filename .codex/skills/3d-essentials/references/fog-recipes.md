# Fog Recipes

Reference for `skills/3d-essentials/SKILL.md` — Compatibility-safe depth and height fog.

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Fog

### Depth & Height Fog (Environment)

Simple fog configured on the Environment resource:

#### GDScript

```gdscript
var env: Environment = $WorldEnvironment.environment

# Depth fog — increases with distance from camera
env.fog_enabled = true
env.fog_light_color = Color(0.7, 0.75, 0.8)
env.fog_density = 0.01

# Height fog — thicker below a certain Y level
env.fog_height = 0.0
env.fog_height_density = 0.5

# Sun scattering — tints fog with directional light color
env.fog_sun_scatter = 0.3
```

Compatibility does not provide volumetric fog or localized `FogVolume` rendering. For a local mist effect, use a bounded transparent mesh or particles and verify overdraw on the Web export.

---

# Flipbook Animation (2D)


> ← Back to [SKILL.md](../SKILL.md)

---
### Setup

1. Set the particle **Texture** to a sprite sheet
2. On the GPUParticles2D, set the **CanvasItemMaterial** (not the process material):
   - Material → New CanvasItemMaterial
   - Enable **Particle Animation**
   - Set **H Frames** and **V Frames** to match the sheet layout
3. On the ParticleProcessMaterial, configure Animation:
   - `anim_speed_min` / `anim_speed_max` — playback speed
   - `anim_offset_min` / `anim_offset_max` — random start frame

```gdscript
# Process material animation settings
mat.anim_speed_min = 1.0
mat.anim_speed_max = 1.5
mat.anim_offset_min = 0.0
mat.anim_offset_max = 0.5  # random start position in the animation
```


> Use **Add** blend mode on the CanvasItemMaterial for particles with black backgrounds (fire, sparks, magic).

---

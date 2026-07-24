# Collision Layers and Masks — Setup Recipes

Reference for `skills/physics-system/SKILL.md` — layer naming, code setters, bitmask shorthand, Inspector export hints.

> ← Back to [SKILL.md](../SKILL.md)

---

## Naming Layers

**Project Settings → Layer Names → 2D Physics** (or 3D Physics). Typical layer set: `Player / Enemy / World / Projectile / Pickup / Trigger`.

## Setting Layers and Masks


```gdscript
collision_layer = 0
set_collision_layer_value(1, true)   # Add to layer 1 (Player)
collision_mask = 0
set_collision_mask_value(3, true)    # Scan layer 3 (World)
```

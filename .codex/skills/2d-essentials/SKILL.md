---
name: 2d-essentials
description: Use when working with TileMapLayer, parallax, 2D lights and shadows, canvas layers, particles, custom drawing, and 2D meshes in Godot 4.6 GDScript Web projects
---

# 2D Essentials in Godot 4.6

Use Godot 4.6.x GDScript APIs that work in Builda's single-threaded Web export.

> **Related skills:** **player-controller** for CharacterBody2D movement patterns, **animation-system** for AnimatedSprite2D and sprite animation, **physics-system** for collision shapes and raycasting, **camera-system** for Camera2D follow and shake, **shader-basics** for 2D shaders and post-processing, **godot-optimization** for rendering and draw call tuning.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. Canvas Layers and Draw Order

### Draw Order Rules

Within a single canvas layer, nodes draw in **scene tree order** — nodes listed lower in the Scene panel draw **on top**. Use `z_index` to override without rearranging the tree.

```gdscript
# Draw this node above siblings (default z_index is 0)
z_index = 10

# Keep z_index relative to the parent (default: true)
z_as_relative = true

# Set false only when this node needs an absolute canvas-layer Z index.
# z_as_relative = false
```

### CanvasLayer

`CanvasLayer` creates a separate rendering layer with its own transform, independent of the camera. Higher `layer` values draw on top.

| Layer | Typical Use |
|-------|-------------|
| -1 | Parallax backgrounds |
| 0 | Default game layer (all Node2D without CanvasLayer) |
| 1 | HUD / UI overlay |
| 2 | Pause menu, screen transitions |

```
# Scene tree example
Main
├── ParallaxBackground (CanvasLayer, layer = -1)
│   └── Parallax2D
├── World (Node2D — default layer 0)
│   ├── TileMapLayer
│   └── Player
└── HUD (CanvasLayer, layer = 1)
    └── Control
```

> **Note:** CanvasLayers are NOT required to control draw order. For objects within the same game world, use `z_index` or scene tree ordering. CanvasLayers are for elements that should be independent of the camera (HUD, parallax, transitions).

### Canvas Transform

`Camera2D` works by modifying the viewport's `canvas_transform`. For manual control:

```gdscript
# Scroll the canvas directly (equivalent to camera movement)
get_viewport().canvas_transform = Transform2D(0, Vector2(-200, 0))
```

### Coordinate Conversion

```gdscript
# Local to canvas (world) coordinates
var world_pos: Vector2 = get_global_transform() * local_pos
var local_pos: Vector2 = get_global_transform().affine_inverse() * world_pos

# Local to screen coordinates (accounts for camera, stretch, window)
var screen_pos: Vector2 = get_viewport().get_screen_transform() * get_global_transform_with_canvas() * local_pos
```

---


## 2. TileMap System

`TileMapLayer` is the Godot 4.6 API — one tilemap = one node = one layer. Drive painting with a `TileSet` resource (atlas + properties + physics + custom data). Use **terrain autotiling** for biome-aware tile selection and **scene collection tiles** for placing scene instances on tiles.

> See [references/tilemap.md](references/tilemap.md) for TileSet setup, atlas/physics/terrain configuration, custom tile data, scene collection tiles, and the Godot 4.6 tile-collision-bump behavior.

---

## 3. Parallax Scrolling

Use `Parallax2D` in Godot 4.6 instead of the older `ParallaxBackground`/`ParallaxLayer` pair. Set `scroll_scale` per layer (0 = static, 1 = follows camera 1:1, fractional values for depth). Add `repeat_size` for infinite tiling.

> See [references/parallax.md](references/parallax.md) for `Parallax2D` setup, side-scroller layer example, infinite repeat, split-screen parallax, common mistakes.

---

## 4. 2D Lights and Shadows

`PointLight2D` and `DirectionalLight2D` cast lighting onto sprites — pair with a normal map for 3D-style shading or use additive-blend illumination on flat sprites. Cast shadows with `LightOccluder2D`.

> See [references/lights-and-shadows.md](references/lights-and-shadows.md) for node overview, PointLight2D properties, shadow settings, cull masks, occluders, 2D normal maps, pixel-art lighting tips, and additive-sprite fake-light tricks.

---

## 5. 2D Particle Systems

`GPUParticles2D` for high counts (≥ 50 particles, GPU-driven), `CPUParticles2D` for low counts or platforms without GPU support. Both share the same `ParticleProcessMaterial` interface; differences are mainly performance.

> See [references/2d-particles.md](references/2d-particles.md) for the GPU-vs-CPU distinguishing choices, basic setup, ParticleProcessMaterial 2D properties, emission from textures, flipbook, visibility rect, common 2D recipes.

---

## 6. Custom Drawing

Override `_draw()` on any `CanvasItem` to draw lines, polygons, text, or arbitrary shapes. Call `queue_redraw()` to trigger a re-render (never call `_draw()` directly).

> See [references/custom-drawing.md](references/custom-drawing.md) for the `_draw()` method, redrawing patterns, full drawing-methods reference, default font usage, `@tool` editor preview, line-width gotchas.

---

## 7. 2D Meshes

### When to Use

`MeshInstance2D` replaces `Sprite2D` when large transparent areas waste GPU fill rate. The GPU draws the entire texture quad including fully transparent pixels — a mesh eliminates those.

### Converting Sprite2D to MeshInstance2D

1. Select the `Sprite2D`
2. Menu: **Sprite2D → Convert to MeshInstance2D**
3. Adjust growth and simplification parameters
4. Click "Convert 2D Mesh"

Best candidates:
- Screen-sized images with transparency
- Parallax layers with irregular shapes
- Layered images with large transparent borders
- Mobile/low-end GPU targets

---

## 8. 2D Antialiasing

### Per-Node Antialiasing (Recommended)

Many drawing methods support an `antialiased` parameter:

```gdscript
draw_line(Vector2.ZERO, Vector2(100, 50), Color.WHITE, 2.0, true)  # antialiased = true
```

`Line2D` has an `antialiased` property; enable it in the Inspector or set `line.antialiased = true`. This generates additional geometry, so it does not require MSAA.

Compatibility Web projects should use per-node antialiasing and asset-appropriate filtering rather than renderer-specific MSAA. For pixel art, leave antialiasing off where deliberately sharp edges are part of the style.

---

## 9. 2D Snapping and Pixel-Perfect

### Editor Snapping

Three-dot menu in the 2D toolbar:
- **Grid Step** — snap to grid (configure Grid Offset and Step)
- **Rotation Step** — snap rotation to degrees
- **Smart Snap** — snap to parent, node anchors, sides, centers, guides

### Runtime Pixel Snap

For pixel-art games, enable pixel snapping to prevent subpixel jitter:

- **Node2D:** Project Settings → Rendering → 2D → Snapping → `Snap 2D Transforms to Pixel`
- **Vertices:** Project Settings → Rendering → 2D → Snapping → `Snap 2D Vertices to Pixel`
- **Controls:** Project Settings → GUI → General → `Snap Controls to Pixels`

---

## 10. Implementation Checklist

- [ ] Background is a Sprite2D or ColorRect (not the default clear color) so it receives 2D lighting
- [ ] TileSet is saved as an external `.tres` resource for reuse across levels
- [ ] TileSet has `Use Texture Padding` enabled to prevent texture bleeding
- [ ] Parallax2D textures have top-left at (0,0), not centered
- [ ] `repeat_size` matches actual texture dimensions
- [ ] `repeat_times` is increased if the camera can zoom out
- [ ] LightOccluder2D nodes are added to shadow-casting objects when shadows are enabled
- [ ] Light and occluder cull masks are configured to avoid unnecessary light calculations
- [ ] GPUParticles2D has a valid Visibility Rect (auto-generate via Particles menu)
- [ ] `queue_redraw()` is called when custom drawing state changes
- [ ] Collision shapes on tiles use the Physics Layer system, not manual CollisionShape2D nodes
- [ ] Large transparent sprites are converted to MeshInstance2D on mobile/low-end targets

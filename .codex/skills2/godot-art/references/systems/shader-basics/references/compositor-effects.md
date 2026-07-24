# Compositor Effects Are Outside the Builda Web Target

> Back to [SKILL.md](../SKILL.md)

Builda's default target is Godot 4.6, GDScript, single-threaded Web export, and the Compatibility renderer. Do not use `CompositorEffect`, `RenderingDevice`, compute shaders, or custom render passes for this target.

Use one of these compatible alternatives instead:

- a `canvas_item` shader on a full-screen `ColorRect` for 2D post-processing;
- a `SubViewport` rendered through a `TextureRect` with a `canvas_item` shader;
- Compatibility-supported `WorldEnvironment` properties for built-in 3D effects;
- per-object `ShaderMaterial` effects for outlines, dissolves, flashes, and palette changes.

If a project explicitly changes its renderer and export target, treat compositor work as a separate, opt-in skill rather than extending this default skill.

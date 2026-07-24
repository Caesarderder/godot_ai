---
name: shader-basics
description: Write or review Godot 4.6.x canvas_item and spatial shaders for Builda's GDScript single-threaded Web runtime using the Compatibility renderer. Use for uniforms, UV animation, palette/flash/dissolve effects, basic spatial materials, screen textures, depth textures, and Web shader validation.
---

# Shader Basics

Target Godot 4.6.x Web export and the Compatibility renderer. Shader code lives in `.gdshader`; use GDScript to set parameters.

## Renderer boundary

Use `canvas_item` and `spatial` shader features available in Compatibility/WebGL 2. Do not use RenderingDevice, compute shaders, custom compositor passes, normal/roughness buffers, temporal rendering data, or advanced renderer-only features.

Keep a fallback material or effect-off path for devices that cannot compile a complex shader reliably.

## Minimal canvas shader

```glsl
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = tex * tint;
}
```

Preserve source alpha unless the effect intentionally changes it. For screen reads, declare a sampler with `hint_screen_texture`; do not use removed legacy screen globals.

```glsl
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
    COLOR = texture(screen_texture, SCREEN_UV);
}
```

Screen-reading transparent materials can trigger a back-buffer copy. Keep their viewport coverage and layer count low.

## Minimal spatial shader

```glsl
shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    ALBEDO = albedo_color.rgb;
    ROUGHNESS = roughness;
}
```

Prefer `StandardMaterial3D` until custom shader behavior is necessary. Compatibility uses lower color precision than advanced renderers, so check gradients, emission, and banding in Web.

## Uniforms from GDScript

```gdscript
@onready var material := $Sprite2D.material as ShaderMaterial

func set_hit_flash(amount: float) -> void:
    if material == null:
        return
    material.set_shader_parameter(&"flash_amount", clampf(amount, 0.0, 1.0))
```

Duplicate a shared `ShaderMaterial` before per-instance parameter changes when each instance needs independent values.

Animate occasional parameters with Tween or AnimationPlayer. Use `_process()` only for continuous time-dependent behavior that cannot be expressed with shader `TIME` or a lower-frequency update.

## Texture hints and sampling

- Use `source_color` for color uniforms/textures that require color-space conversion.
- Match filtering to the art style; pixel art normally uses nearest filtering.
- Enable repeat only when the source texture and target devices support the intended tiling.
- Limit neighbor samples for outlines and blur-like effects; sample count multiplies fragment cost.
- Avoid large dynamic loops and divergent branches in fullscreen shaders.

## Depth and screen effects

Compatibility supports screen and depth textures but not the normal/roughness buffer. Reconstruct only what is actually available and handle missing/invalid depth contexts. Prefer a `ColorRect` overlay or `SubViewport` composition for simple full-screen effects.

Do not implement an effect by relying on a compositor or low-level rendering callback.

## Web validation

- Check shader compilation in the exported browser build and browser console.
- Test transparency, premultiplied assumptions, and color precision.
- Measure GPU frame time at target resolution; fullscreen cost grows with pixels and samples.
- Test first appearance for shader compilation stutter.
- Verify all optional uniforms have safe defaults.
- Confirm the effect degrades acceptably when disabled.

## References boundary

No bundled reference is required by default. Existing `references/` files are optional legacy material and may describe other renderers, low-level compositor paths, languages, or engine versions. Do not load them automatically. In particular, compositor-oriented references are outside the Builda Web target.

## Checklist

- [ ] Shader type matches the target node.
- [ ] Every API and buffer exists in Compatibility.
- [ ] No low-level rendering or compute dependency exists.
- [ ] Source alpha and color-space hints are correct.
- [ ] Shared materials are duplicated only for independent parameters.
- [ ] Fullscreen and multi-sample effects have measured budgets.
- [ ] Exported Web compilation and visual output are verified.

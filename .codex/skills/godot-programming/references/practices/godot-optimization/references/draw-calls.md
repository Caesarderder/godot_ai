# Draw-Call Diagnosis and Optimization

> ← Back to [SKILL.md](../SKILL.md)

Draw-call cost depends on target GPU/browser, resolution, materials, overdraw, and shader work. Capture the same Web scenario before and after a change; do not optimize toward a universal count.

## CanvasGroup Is a Compositing Tool

`CanvasGroup` draws its children into an intermediate buffer so effects such as group opacity, clipping, or a group material can be applied to the combined result. It is not an automatic one-draw-call batching switch and can add framebuffer and fill-rate cost.

Use it when group compositing is required. If considering it for performance, compare draw calls, frame time, and visual output on the target Web device before keeping the change.

## Share Compatible Render State

Unique materials and texture switches can prevent efficient renderer submission. Prefer a shared material and instance uniforms when per-instance variation is required:

```gdscript
# Shader declares: instance uniform vec4 tint : source_color = vec4(1.0);
@export var shared_material: ShaderMaterial


func _ready() -> void:
    $Sprite2D.material = shared_material
    $Sprite2D.set_instance_shader_parameter("tint", Color(1.0, 0.5, 0.2))
```

Duplicating a material creates distinct render state; do not describe that as preserving batching. Validate whether the chosen renderer can combine the actual nodes/materials in the captured scene.

## Atlases

Atlases can reduce texture switches and asset overhead for compatible sprites, tiles, and UI icons. They do not guarantee a single draw call when materials, blend modes, clipping, lighting, or canvas state differ.

- Use a coherent TileSet atlas for related tiles.
- Use `AtlasTexture` regions for compatible UI/sprite assets.
- Avoid giant atlases that increase memory residency or upload cost.
- Re-measure draw calls and frame time after packing.

## Cull Processing and Rendering Work

Use visibility notifiers to stop expensive custom processing only when off-screen behavior is not required:

```gdscript
extends Sprite2D

@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
    visibility_notifier.screen_entered.connect(func() -> void: set_process(true))
    visibility_notifier.screen_exited.connect(func() -> void: set_process(false))
```

Visibility callbacks do not replace gameplay simulation for objects that must continue acting off-screen. Separate visual work from authoritative logic when only rendering-related processing can pause.

## 3D LOD

Use imported mesh LOD or explicit distance-based variants only after measuring geometry/render cost. Validate transitions, collision ownership, and memory; keeping several LOD meshes resident can trade GPU work for memory.

## Verification Checklist

- [ ] Baseline and after captures use the same Web scene and interaction.
- [ ] Material/atlas changes preserve visual output.
- [ ] `CanvasGroup` is justified by compositing semantics or measured evidence.
- [ ] Off-screen culling does not pause required gameplay logic.
- [ ] Draw-call change is evaluated with frame time and overdraw, not alone.

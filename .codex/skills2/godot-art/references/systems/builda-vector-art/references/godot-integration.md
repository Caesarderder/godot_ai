# Godot 4.6 SVG Integration

## 导入原则

- SVG 源文件放入 `res://` 后由 Godot 导入为纹理资源；运行时成本按导入后的纹理评估，不能只看 SVG 文本大小。
- 使用项目规定的 Godot 4.6.x 版本导入和验证。
- UI、2D sprite 默认关闭 mipmaps；Camera2D 大幅缩放或 3D 空间使用时再按实际画面决定。
- 调整 SVG `viewBox` 和几何尺寸优先于在导入配置中反复补偿错误留白。
- 不手改 `.godot/imported/`。需要稳定导入设置时通过 Godot 生成和维护 `.import` sidecar。

## 资源接入

已知路径使用 `preload()`，同类资源较多时建立按业务职责命名的 catalog：

```gdscript
class_name WeaponVisualCatalog
extends RefCounted

const TEXTURES := {
    "pulse": preload("res://assets/generated/vector/weapons/weapon_pulse.svg"),
    "rocket": preload("res://assets/generated/vector/weapons/weapon_rocket.svg"),
}

static func texture_for(id: String) -> Texture2D:
    return TEXTURES.get(id, TEXTURES["pulse"])
```

不要建立笼统的全项目 `utils`；catalog 按武器、敌人、UI 或 VFX 等明确职责拆分。

## 单图角色生命感

```gdscript
animation_time += delta
var moving := direction != Vector2.ZERO
var bob := sin(animation_time * (12.0 if moving else 4.5)) * (3.0 if moving else 1.4)
sprite.position.y = bob
sprite.rotation = lerpf(sprite.rotation, direction.x * 0.08, minf(1.0, delta * 10.0))
var squash := Vector2(0.72, 0.50) if dashing else Vector2(0.60, 0.62)
sprite.scale = sprite.scale.lerp(squash, minf(1.0, delta * 13.0))
```

数值必须结合素材尺寸调整。移动、冲刺和受击状态应有不同节奏，不能永久循环同一个幅度。

## 分件角色

推荐节点结构：

```text
CharacterBody2D
└── VisualRoot
    ├── Body
    ├── HeadPivot
    │   └── Head
    ├── ArmLeftPivot
    │   └── ArmLeft
    ├── ArmRightPivot
    │   └── ArmRight
    └── WeaponPivot
        └── Weapon
```

把连接点放在 pivot 节点原点，Sprite2D 做局部偏移。简单动作使用 Tween，复用动作和状态切换使用 `AnimationPlayer`；复杂骨骼需求再升级到 `Skeleton2D`/`Bone2D`。

## 武器挂点和后坐力

- 武器资产默认朝右。
- `WeaponPivot.rotation` 对准目标。
- 当目标位于左侧时翻转 `Sprite2D.flip_v`，避免上下颠倒。
- 枪口位置通过武器局部坐标 `to_global()` 计算，不从玩家中心猜测。
- 后坐力只短暂改变武器 sprite 的局部位置，再用 `TRANS_BACK` 返回。

## VFX

短生命周期 SVG sprite：

```gdscript
var sprite := Sprite2D.new()
sprite.texture = preload("res://assets/generated/vector/vfx/vfx_impact.svg")
sprite.scale = Vector2.ONE * 0.2
add_child(sprite)

var tween := create_tween().set_parallel(true)
tween.tween_property(sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_QUART)
tween.tween_property(sprite, "rotation", randf_range(-0.5, 0.5), 0.35)
tween.tween_property(sprite, "modulate:a", 0.0, 0.35).set_delay(0.12)
tween.chain().tween_callback(sprite.queue_free)
```

批量碎片使用 Particles 而不是一次创建大量 Tween 节点。Web 单线程预览中应限制瞬时节点数、粒子数和过度透明叠加。

## UI 九宫格

```gdscript
func svg_style(texture: Texture2D, patch: float) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = texture
    style.texture_margin_left = patch
    style.texture_margin_top = patch
    style.texture_margin_right = patch
    style.texture_margin_bottom = patch
    return style
```

- SVG 边缘装饰必须位于 margin 区域。
- 拉伸中心保持平坦，避免中心有必须维持比例的图形。
- 按钮文字由 Godot 主题字体绘制。
- hover/pressed 反馈同时检查鼠标、键盘 focus 和触屏状态。

## 受击与换色

SVG 导入后可使用 CanvasItem shader 做白闪或调色。Shader 只处理纹理像素，不修改 SVG 源文件。白闪应快速衰减，避免覆盖角色识别色太久。

## 验证清单

- Godot 导入无解析错误；
- 目标 Web renderer 下可以加载；
- 16/24/32 像素 UI 图标仍可辨认；
- UI 九宫格拉伸时边角不变形；
- 角色 pivot、朝向和枪口坐标正确；
- 粒子/VFX 结束后释放节点；
- 没有未引用 SVG、绝对路径或远程资源；
- Web 单线程预览中的帧时间和纹理数量可接受。

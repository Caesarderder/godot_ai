# Builda Safe SVG Profile

本规范面向 Godot 4.6 Web 项目中的原创轻量游戏素材。目标是可预测导入、低复杂度和无外部依赖，不覆盖完整 SVG 标准。

## 必需结构

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
  <path d="M12 48L48 12L84 48L48 84Z" fill="#4CC9C0"/>
</svg>
```

- 只能有一个根 `<svg>`。
- 必须声明标准 SVG namespace。
- 必须声明四个有限数字组成的 `viewBox`，宽高大于零且不超过 4096。
- 默认只用 `viewBox` 控制坐标系；没有明确嵌入需求时省略 `width` 和 `height`。
- 文件上限 64 KiB、元素上限 512、路径命令上限 4096。

## 允许元素

基础图形：

```text
svg g path rect circle ellipse line polyline polygon
```

确有渐变、裁切或遮罩需要时：

```text
defs linearGradient radialGradient stop clipPath mask
```

优先基础图形。渐变只使用当前文件中的 `url(#id)`，并保证 ID 唯一且存在。

## 禁止内容

始终禁止：

```text
script foreignObject image text use style
animate animateMotion animateTransform set
a audio video iframe object embed filter
DOCTYPE ENTITY processing instructions
XML comments
```

同时禁止：

- 任意 `on*` 事件属性；
- `href`、`xlink:href`、`class` 和 `style`；
- HTTP(S)、`file:`、`data:`、`javascript:` 或其他外部引用；
- CSS、媒体查询、字体、Base64 和嵌入栅格图；
- 非本文件 fragment 的 `url(...)`；
- XML 实体、文本节点和控制字符。

## 推荐尺寸

| 用途 | 建议 viewBox |
| --- | --- |
| 小图标、粒子 | `0 0 32 32`、`0 0 48 48` |
| 技能、道具、VFX | `0 0 64 64`、`0 0 96 96` |
| 武器、横向组件 | `0 0 96 48`、`0 0 128 64` |
| 角色、敌人 | `0 0 96 96`、`0 0 128 128` |
| 全屏背景 | 与项目基准画布一致，例如 `0 0 1152 648` |

同一资产族尽量共用坐标系。不同文件依靠共同基线、中心点和视觉留白保持替换稳定。

## 视觉复杂度

- 小图标优先 3 到 8 个可识别形状。
- 常规角色优先清晰外轮廓、一个主色、一个强调色和统一深色描边。
- 避免小于目标显示尺寸 1 像素的描边和间隙。
- 避免为了模拟纹理生成大量小 path；改用 Godot Shader 或少量装饰图元。
- 阴影优先半透明椭圆，不使用模糊滤镜。

## 校验失败语义

`validate-svg.mjs` 失败表示文件不属于 Builda 生成规范。必须修改源文件；不要：

- 改名绕过扫描；
- 关闭检查；
- 把相同内容转成 data URI；
- 以内联 HTML 方式预览；
- 仅凭 Godot 当前版本能够导入就判断安全。

校验脚本是 Skill 级质量门禁。平台素材发布仍必须执行自己的边界校验和安全响应策略。

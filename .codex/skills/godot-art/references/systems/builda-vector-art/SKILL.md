---
name: builda-vector-art
description: 为 Builda 的 Godot 4.6 Web 项目创建、修改和验证轻量 SVG 游戏美术，是平台 SVG 素材生产的唯一 owner。用于不需要重型生图时，依据已有游戏视觉设计或资产 brief 制作风格统一的 UI 图标与皮肤、2D 角色和敌人、武器道具、弹丸、场景装饰、粒子纹理与视觉特效，并通过 Godot Tween、AnimationPlayer、Shader 或 Particles 驱动动效；也用于整理已有 SVG 视觉体系、检查 Godot 兼容性和安全子集。不要用它决定 HUD 信息层级和摆放，也不要用于写实、厚涂、复杂纹理或摄影类素材。
---

# Builda Vector Art

把 SVG 作为 Builda 的默认轻量美术媒介，把动画交给 Godot。生成的源文件属于当前用户项目；本 Skill 只提供生产流程、兼容规范和确定性校验，不保存租户素材。

## 核心边界

- 先读取项目根 `AGENTS.md`、现有素材目录、主场景和视觉相关脚本；项目规范优先。
- HUD 层级、图标位置、画面构图或玩法反馈尚未确定时，先使用 `game-visual-design` 形成实现合同；本 Skill 消费资产 brief，不越权替代游戏视觉设计。
- 所有产物只写入当前 Godot 项目，不读取宿主机私有目录，不引入远程依赖。
- 沿用已有素材目录。新项目默认使用 `assets/generated/vector/<domain>/`，其中 `domain` 取 `ui`、`characters`、`enemies`、`weapons`、`projectiles`、`props`、`vfx` 或 `environment`。
- 只修改 SVG 源文件和明确需要的 Godot 场景、资源或脚本；不手改 `.godot/imported/`。
- SVG 只表达静态形状。禁止在 SVG 内嵌脚本、交互、字体、外部资源或动画。
- 安全校验脚本是生成质量门禁，不替代平台发布边界的素材校验。

## 选择媒介

按以下顺序选择最轻的充分方案：

1. 纯色矩形、圆形、进度值或频繁变化的几何图形：优先 `StyleBoxFlat`、`Gradient`、`Polygon2D` 或 `_draw()`。
2. 需要稳定轮廓、复用、缩放、独特造型或统一视觉语言：使用 SVG。
3. 需要写实材质、厚涂笔触、复杂光照、照片感或高频纹理：说明 SVG 不适合，再使用生图或栅格素材。

不要因为 SVG 容易生成就把所有几何背景拆成文件，也不要因为角色会动就直接升级到生图。

## 工作流

### 1. 接收并补齐视觉契约

优先读取 `game-visual-design` 输出的视觉命题、组件状态和资产清单，再结合已有素材确定：

- 3 到 7 个主色及各自语义；
- 统一轮廓色、描边宽度和圆角倾向；
- 目标显示尺寸与 `viewBox`；
- 形状语言，例如柔软圆润、硬边机械或晶体尖角；
- 明暗层级、可读性和剪影差异。

每个资产必须能关联到明确的游戏元素、界面组件或反馈事件。缺少用途、目标尺寸或状态定义时先补齐 brief，不先画一批候选图标再反推用途。

已有视觉体系存在时必须复用，不能为新增图标另起一套风格。需要具体几何配方时读取 [references/visual-recipes.md](references/visual-recipes.md)。

### 2. 设计资产族而不是孤立文件

先列出同一资产族的职责和差异，再生成文件。例如敌人族共享描边、眼睛和阴影，但通过轮廓、主色、尺度和危险特征区分。

命名使用小写英文和下划线：

```text
ui_health.svg
enemy_crystal_brute.svg
weapon_orb_caster.svg
vfx_impact_ring.svg
```

同一物件的状态使用明确后缀，如 `_normal`、`_hover`、`_pressed`、`_disabled`、`_elite`，不要用 `new`、`final`、`v2`。

### 3. 生成受限 SVG

- 必须声明 `xmlns="http://www.w3.org/2000/svg"` 和 `viewBox`。
- 优先使用少量 `path`、`circle`、`ellipse`、`rect`、`line`、`polyline`、`polygon` 与 `g`。
- 文字必须由 Godot `Label` 配合项目字体渲染；SVG 内禁止 `<text>`。
- 不嵌入 PNG/JPEG，不引用 URL，不使用 CSS、事件属性或 SVG 内置动画。
- 保持轮廓简洁，在实际显示尺寸下仍能辨认；小图标不要依赖细碎内部结构。
- 默认避免滤镜。光晕、白闪、溶解、拖尾和颜色变化交给 Godot Shader、Tween 或 Particles。

完整允许项、复杂度上限和失败语义见 [references/safe-svg-profile.md](references/safe-svg-profile.md)。

### 4. 确定性校验

每次新建或修改 SVG 后，运行本 Skill 的校验脚本。根据当前已加载 `SKILL.md` 的绝对路径解析脚本位置：

```bash
node <skill-dir>/scripts/validate-svg.mjs <svg-file-or-directory> [...more-paths]
```

校验失败时修复源文件并重新运行，禁止跳过、放宽规则或用浏览器能显示作为替代结论。

### 5. 接入 Godot

根据职责选择：

- 独立对象：`Sprite2D` 或 `TextureRect`；
- 可拉伸 UI：`StyleBoxTexture` 并设置 texture margins；
- 图标：`TextureRect`、`Button.icon` 或主题资源；
- 瞬时 VFX：临时 `Sprite2D` 配合 Tween；
- 粒子：作为 `CPUParticles2D`/`GPUParticles2D` 纹理；
- 可动角色：单图整体变形，或多分件挂到 `Node2D`/`Bone2D` 层级。

需要动画、UI 九宫格和导入策略时读取 [references/godot-integration.md](references/godot-integration.md)。

### 6. 验证真实结果

1. 用项目规定的硬超时执行 Godot 资源导入；不得无限等待。
2. 运行最小项目烟测，确认没有导入、解析或资源路径错误。
3. 在目标尺寸检查轮廓、描边、透明边缘、按钮拉伸和角色朝向。
4. 对动态素材检查静止、运动、命中、消失四个阶段，而不只看 SVG 文件本身。
5. 检查新增 SVG 是否确实被场景或代码引用，删除未采用的候选文件。

## 动效原则

- 单图角色：使用浮动、倾斜、挤压拉伸、闪白和透明度建立生命感。
- 分件角色：以身体为根，头、手臂、武器和饰品分别设置 pivot，再用 `AnimationPlayer` 或 Tween 驱动。
- 武器：独立挂点控制瞄准、翻转、后坐力和枪口位置。
- VFX：SVG 负责清晰形状，Tween/Particles 负责缩放、旋转、散射、颜色和衰减。
- UI：SVG 负责边框和装饰，Godot Control 容器负责布局；不要把文字和动态数值画进 SVG。
- Web 预览优先短生命周期、少节点和可复用纹理，不用复杂矢量路径弥补动画设计。

## 完成标准

- 素材与项目现有视觉契约一致，资产族之间既统一又可辨识。
- 所有新增或修改 SVG 通过 `validate-svg.mjs`。
- Godot 导入和最小烟测通过，Web 目标下无资源错误。
- 动效由 Godot 驱动，SVG 内没有脚本、外链、文字、交互或动画。
- 文件落在语义明确的项目目录，被真实资源引用且没有遗留候选稿。
- 最终说明生成了哪些资产、接入了哪些节点/动画、执行了哪些验证，以及仍未进行的视觉验收。
- HUD 资产能够追溯到 `game-visual-design` 的信息层级和组件状态；本 Skill 没有擅自改变摆放与玩法语义。

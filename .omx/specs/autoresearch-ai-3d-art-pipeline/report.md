# AI 辅助 3D 游戏美术完整工作流调研

> 调研日期：2026-07-23。面向 Godot 4，也兼容常见 Unity/Unreal DCC 管线。

## 一句话结论

目前没有一套“从原画到可上线角色”能够可靠全自动完成的 AI 产品。真正能落地的路线是：

`AI 概念与多视图 → AI 生成高模/草模 → Blender 生产化 → Substance/Marmoset 烘焙贴图 → 自动绑定 → AI 动捕/动作库 → 动画清理 → GLB 进入 Godot`

推荐把 **Blender 作为单一资产真源和管线中枢**。Meshy、Tripo、Rodin 等负责候选几何与纹理，不能取代最终拓扑、UV、蒙皮和引擎内验收。自动化程度从高到低大致为：静态小道具/远景环境 > 硬表面资产 > NPC > 英雄角色/生物。

## 推荐的主生产方案

| 阶段 | 推荐工具 | 输入 → 输出 | 自动化边界 | 必须的人工质量门禁 |
|---|---|---|---|---|
| 1. 风格与原画 | FLUX.2/Kontext、Firefly 或 Midjourney；本地 ComfyUI | 文字、风格板 → 角色/道具定稿 | 可批量探索；设计决策不可自动批准 | 版权来源、轮廓、材质、可制造结构 |
| 2. 三视图/多视图 | ComfyUI + IP-Adapter + ControlNet；FLUX 多参考；人工 PS/Krita 对齐 | 正面定稿 → front/side/back + 细节图 | 可生成推测视角；不能保证严格正交与结构一致 | 三视图同高、同尺度；服饰/装备闭合逻辑一致 |
| 3. 图生 3D | Meshy / Tripo / Hyper3D Rodin 三者 A/B；保密项目用本地模型实验 | 1–4 张图 → 高模/带贴图 GLB | 可批量产候选；不能自动判定背面和薄片正确 | 剪影、背面、薄片、手指、拓扑、部件是否粘连 |
| 4. 清理与分件 | Blender | AI 网格 → clean high、独立部件、统一尺度 | 可脚本检测/修复部分网格问题；分件语义需人工 | 非流形、洞、重叠面、法线、pivot、命名、朝向 |
| 5. 低模/拓扑 | Quad Remesher / Instant Meshes / Blender，角色关键区人工重拓扑 | clean high → animation-ready low | 自动 remesh 仅作初稿；不保证变形 edge flow | 肩肘膝髋、眼口手指环线；硬边与 UV seam 配合 |
| 6. UV | Blender；可用自动展开作初稿 | low → UV1，必要时 UV2 | 道具/远景可高度自动；角色接缝和密度需人工 | 无重叠、合理接缝、统一 texel density、padding 足够 |
| 7. 烘焙/纹理 | Substance 3D Painter；高要求烘焙用 Marmoset | high + low + cage → PBR maps | 可批量 bake/生成底稿；cage 错误与材质逻辑需人工 | 法线波纹、投射穿帮、接缝、色彩空间、材质物理合理性 |
| 8. 骨骼/蒙皮 | AccuRIG、Mixamo 或 Tripo；Blender Rigify/权重精修 | A/T pose low → skeleton + skin | 标准角色可自动起稿；脸、手、衣物和特殊肢体需精修 | 极限姿势、肩髋塌陷、手指、脸、衣服/装备穿插 |
| 9. 动画 | Mixamo 动作库；Rokoko/DeepMotion 视频动捕；Cascadeur/Blender 清理 | 视频/动作 → retargeted clips | 可生成/重定向初稿；接地、重心和表演不可自动批准 | 脚滑、root motion、接地、循环首尾、穿插、重心 |
| 10. Godot 交付 | Blender glTF 2.0 → Godot Advanced Import | `.blend` 真源 → `.glb` + textures | 导出/导入检查可脚本化；视觉和性能验收保留人工 | SkeletonProfile/BoneMap、动画名、材质、LOD、碰撞与性能 |

## 每个环节怎么做

### 1. 2D 原画与一致性

先生成设计探索，不要一开始就要求 AI 同时生成整张 turnaround。锁定正面全身、脸部、材质关键词、服装层级和道具分件后，再做其他视角。

- 云端高效率：FLUX.2/Kontext 或 Midjourney 的参考图能力维持角色/风格一致性。
- 相对可控且可本地：ComfyUI 中用 IP-Adapter 保身份，用 ControlNet/Canny/Depth/OpenPose 保轮廓与姿势。
- 商业素材来源更敏感时可评估 Firefly；Adobe 公开说明其训练数据策略及用户内容政策，但仍应保留每个输入素材的授权记录。

[FLUX.2 官方说明](https://bfl.ai/blog/flux-2)、[ComfyUI Kontext 工作流](https://docs.comfy.org/tutorials/flux/flux-1-kontext-dev)、[ControlNet 论文](https://arxiv.org/abs/2302.05543)、[IP-Adapter 项目](https://ip-adapter.github.io/)、[Adobe Firefly 方法说明](https://www.adobe.com/ai/overview/firefly/gen-ai-approach.html)

### 2. 三视图不是“一键提示词”

建议建立正、侧、背三栏正交模板，统一头顶、肩、腰、膝、脚底基线。每个视角分别生成，最后由美术在 Photoshop/Krita 中校正比例、服装接缝、装备位置和背面结构。Zero123++、Wonder3D、Stable Zero123 可补猜其他角度，但其输出是生成式推测，不是工程正投影图。

角色最好使用 A-pose：腋下更易建模和贴图，同时比大幅 T-pose 更接近自然肩部形态。背景用纯色、无强阴影、无遮挡；武器、背包、披风最好另出分件图。

[Zero123++](https://arxiv.org/abs/2310.15110)、[Wonder3D](https://arxiv.org/abs/2310.15008)、[ComfyUI Stable Zero123 示例](https://comfyanonymous.github.io/ComfyUI_examples/3d/)

### 3. 2D/多视图生成 3D

生产中最实际的选择是同一组参考图并行跑 Meshy、Tripo、Rodin，按资产选结果，不预先押注单一平台。

| 工具 | 强项 | 适合 | 关键限制 |
|---|---|---|---|
| Meshy | 单图/多图、PBR、remesh、rig、animation、完整 API | 原型、道具、NPC、批量管线 | quad-dominant 不等于动画级拓扑；角色仍需重做关键环线 |
| Tripo | image/multiview、PBR、retopo、rig-check/rig/retarget，API 链完整 | 批量资产和快速角色链路 | 官方现支持双足、四足、六/八足、鸟、蛇形和水生 rig；复杂骨骼、权重和重定向仍需人工验收；remesh 会破坏已有 rig 数据 |
| Hyper3D Rodin | 多图、高质量形体、Quad 模式、常见格式 | 英雄资产高模候选、产品/硬表面 | 云端成本与数据政策需按项目确认；[Rodin API](https://developer.hyper3d.ai/api-specification/rodin-generation) 提供图像输入、Quad 模式等参数 |
| Hunyuan3D-2.1 | 本地形体与 PBR 纹理，可做私有化实验 | 有 GPU/工程团队、机密原型 | 资源占用高；社区许可证不是 MIT/Apache，商业前需法务确认 |
| Stable Fast 3D / TripoSR | 快速本地单图重建 | 静态占位物、小道具实验 | 背面、角色结构、多视图一致性与生产工具链较弱 |
| TRELLIS 系列 | 高质量研究与多种 3D 表达 | R&D/本地工程评估 | TRELLIS.2 代码仓库为 MIT，但项目页同时对“页面提供的材料”声明仅供学术研究；代码、权重、演示和数据应分别核对许可 |

Meshy 官方 API 支持 1–4 张多图输入；Remesh API 可生成 quad-dominant 或三角网格并输出 GLB/FBX/OBJ 等。[Meshy 文档](https://docs.meshy.ai/en)、[Multi-Image API](https://docs.meshy.ai/en/api/multi-image-to-3d)、[Remesh API](https://docs.meshy.ai/en/api/remesh)。Tripo 当前 API 提供从 image/multiview 到 rig/retarget 的链路，[官方快速入门](https://developers.tripo3d.ai/en/docs/quick-start) 和 [Auto Rig](https://developers.tripo3d.ai/en/docs/animations-rig) 有明确接口。

### 4–6. 模型生产化、重拓扑与 UV

AI 结果应拆成两份：不可破坏的 `*_high` 和用于游戏的 `*_low`。进入 Blender 后先应用尺度/旋转，设米制单位，面向 Godot 的 forward 统一为 `-Z`，再处理：非流形、内面、薄片、重复面、法线、材质槽、独立部件、pivot 和命名。

自动重拓扑适合第一遍：Quad Remesher、Instant Meshes 或 Blender 内置工具。但“全四边面”并不等于“可变形”：英雄角色仍必须人工修复眼口、肩、肘、腕、髋、膝、踝和手指环线。硬表面要检查轮廓、硬边、支撑边和 UV seam。先定稿低模，再定稿 UV，之后才做最终烘焙。

[Blender Retopology](https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html)、[Quad Remesher](https://exoside.com/)、[Instant Meshes](https://github.com/wjakob/instant-meshes)

### 7. PBR 纹理与烘焙

AI 生成纹理可用作底稿，不建议直接当最终材质。Substance Painter 或 Marmoset 用 high→low + cage 烘焙 Normal、AO、Curvature、Position、Thickness、ID 等 mesh maps，再以可编辑材质层重建磨损、污渍和材质差异。Substance 官方说明烘焙是把高模细节保存到低模纹理；Marmoset 对 cage、skew、offset 的逐点修正更方便。

Godot 推荐 metallic-roughness PBR。最基本输出为 BaseColor(sRGB)、Normal(linear)、Roughness(linear)、Metallic(linear)、AO(linear)，按项目决定是否把 AO/Roughness/Metallic 打成 ORM。不要把光照和投影烘进 BaseColor；头发/树叶优先测试 Alpha Scissor/Hash。

[Substance Painter Baking](https://helpx.adobe.com/substance-3d-painter/using/baking.html)、[Marmoset Baking](https://marmoset.co/toolbag/baking/)、[glTF PBR](https://www.khronos.org/gltf/pbr/)

### 8. 骨骼绑定

- 最快原型：Mixamo，免费且动作库丰富，但官方说明仅适合双足人形，并对非标准比例、翅膀/尾巴、大块头发服装有限制。
- 更可控的人形：AccuRIG，支持 A/T pose、多网格和关节点人工修正。
- Blender 本地：Rigify 生成控制 rig，最终只导出 deform bones。
- 四足、怪物、面部表情、可换装：默认视为需要技术美术/绑定师人工处理，不应依赖一键绑定。

自动权重完成后至少测试：深蹲、抬臂、抱胸、踢腿、扭腰、握拳、极限表情。绑定应发生在最终拓扑之后；重拓扑/重建网格通常会使骨骼权重失效。

[Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)、[AccuRIG](https://actorcore.reallusion.com/static-page/auto-rig/pre_page/accurig/accurig.html)、[Blender Rigify](https://docs.blender.org/manual/en/latest/addons/rigging/rigify/basics.html)

### 9. 骨骼动画

将动画拆成“获得动作”和“清理动作”两步：

- 预设库：Mixamo，适合 locomotion 和原型。
- 视频转动作：Rokoko Vision 或 DeepMotion；动作越少遮挡、镜头越固定、照明越均匀越好。
- 清理：Rokoko Studio 做 retarget/foot lock 等；Cascadeur 或 Blender 修脚滑、重心、弧线、接触、穿插和循环。
- 面部/手指：单目视频结果不要与专业面捕/手套等同；英雄镜头要单独提高方案等级。

统一动作命名如 `idle`, `walk_fwd`, `run_fwd`, `attack_01`；明确 in-place 与 root-motion 两套策略；导出前 bake constraints，30/60 fps 由项目基线统一。

[Rokoko Vision](https://www.rokoko.com/products/vision)、[DeepMotion Animate 3D](https://www.deepmotion.com/doc/animate-3d)、[Cascadeur AutoPosing](https://cascadeur.com/help/tools/animation_tools/autoposing)

### 10. Godot 交付

Blender 保留 `.blend` 真源；对团队构建和版本稳定性，推荐显式导出 `.glb`，而不是让每台机器直接导入 `.blend`。glTF 可携带 mesh、PBR 材质、纹理、skin、骨骼动画和 shape keys。Godot 的高级导入可以抽取材质/网格、设置每网格骨骼影响数、导入动画并使用 import script 自动后处理。

Godot 侧建立 `SkeletonProfileHumanoid + BoneMap` 以共享人形动画；骨骼采用常见英文名以提高自动映射率。Blender 的动作放入 Actions/NLA 并用稳定命名导出。最终检查 backface culling、切线/法线、纹理色彩空间、动画 RESET pose、root motion、LOD、碰撞体和材质开销。

[Godot 3D 场景导入](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)、[Godot 骨骼重定向](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)、[Blender glTF 2.0](https://docs.blender.org/manual/en/4.5/addons/import_export/scene_gltf2.html)

## 按资产类型选择不同路线

### 英雄角色/近景生物

AI 用于原画、多视图和高模候选；人工重拓扑、UV、蒙皮、面部和动画清理是默认预算。不要把自动 quad remesh 当最终变形拓扑。建议 `FLUX/ComfyUI → Meshy/Tripo/Rodin 候选 → Blender 人工低模 → Substance/Marmoset → AccuRIG/Rigify + 人工权重 → 动捕 + Cascadeur/Blender`。

### NPC/风格化低模角色

可提高自动化比例：多视图生成 → Tripo/Meshy retopo → Blender 修关节和 UV → AccuRIG/Mixamo → 动作库/视频动捕。仍要做五个极限姿势测试和引擎性能测试。

### 硬表面道具/武器

单图或 3–4 视图生成很有效，但应拆分活动件，重建平面/圆柱和锋利轮廓。自动 UV、自动 LOD 和批量烘焙更可行；检查对称性、孔洞、厚度和 pivot。

### 环境/模块化场景

AI 适合出风格、雕花高模和杂物变体，不适合直接定义模块尺寸。先由关卡设计规定 1m/2m/4m 模数、网格吸附、pivot、碰撞和 texel density，再让 AI 在约束内产装饰件。墙地面优先使用可平铺材质、trim sheet、decal，而不是每件独立 4K 贴图。

## 三套可选组合

### A. 小团队、追求最快落地（推荐起点）

`FLUX/Midjourney → Meshy 与 Tripo A/B → Blender + Quad Remesher → Substance Painter → AccuRIG/Mixamo → Rokoko/DeepMotion → Cascadeur → GLB/Godot`

优点是上手快、API 完整；缺点是订阅多、云端数据和授权要逐项管理。

### B. 低成本方案

`ComfyUI → TripoSR/Stable Fast 3D 或平台免费试跑 → Blender/Instant Meshes → Blender Bake/Paint → Rigify/Mixamo → Blender 动画清理 → GLB`

现金成本低，但人工和工程时间更高；免费 SaaS 产物常带公开、署名或非商业限制，不适合作为默认商业管线。

### C. 保密/私有部署方案

`本地 ComfyUI → 本地 Hunyuan3D/TripoSR 类模型 → Blender 自动脚本 → Substance/Blender → Rigify → 自有视频/动捕 → GLB`

这不是“免费方案”：需要 GPU、模型运维、固定版本、队列、资产追踪和法务审查。Hunyuan3D 使用社区许可证，不能按标准开源许可证想当然。TRELLIS.2 的代码仓库为 MIT，但项目页对页面材料另有学术研究用途声明，因此必须分别审查代码、权重、演示与训练数据，而不能只看仓库根许可证。

## 授权、隐私和成本

1. 免费档通常风险最高：模型可能公开、要求 CC BY、仅限非商业，或平台保留更多权利。
2. “允许商用”不等于独占、不侵权或可直接转售模型本体。
3. 每个资产记录：输入来源、生成工具/版本、账号档位、生成日期、提示词/参考图、人工修改、条款快照。
4. 未公开 IP 和客户资产只进入明确“不训练、私有、可删除、有限留存”的企业服务或本地管线。
5. API 必须走官方接口，不用网页自动化绕过额度或限流。

| 服务 | 免费/付费产物与商用 | 训练/隐私要点（截至调研日） | 生产建议 |
|---|---|---|---|
| Meshy | 免费输出按其条款采用 CC BY 4.0；付费计划提供更完整商用与私有能力 | 非 Enterprise 输入/输出可能用于训练；API 文件有留存期限 | 商业项目至少用合适付费档；机密项目要求 Enterprise 条款 |
| Tripo | 免费模型公开并采用 CC BY 4.0；付费档标注 private models/commercial use | 当前条款声明不把 Inputs/Outputs 用于训练 | 保存当日条款；Studio 与 API 套餐/权利分别核对 |
| Hyper3D Rodin | 付费档提供私有与 API 能力；输出仍受输入与第三方权利约束 | API 数据政策称有限期保存、不用于训练、不共享 | 机密项目仍需合同确认删除、留存与责任边界 |
| 本地模型 | 不向 SaaS 上传，不代表天然可商用 | 代码、权重、训练数据、插件各自可能有不同许可证 | 建立 SBOM/模型清单，逐组件法务审查 |

截至调研日，Meshy、Tripo、Rodin 的免费/付费所有权和训练政策差异明显，价格与条款变化很快，应在正式生产当天重新核对并保存：[Meshy Terms](https://www.meshy.ai/terms-of-use)、[Tripo Terms](https://www.tripo3d.ai/terms)、[Hyper3D Data Policy](https://developer.hyper3d.ai/legal/data-policy)、[Hunyuan3D-2.1 License](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE)、[TRELLIS.2 MIT 代码许可](https://github.com/microsoft/TRELLIS.2/blob/main/LICENSE)及其[项目页材料声明](https://microsoft.github.io/TRELLIS.2/)。

## 建议的质量门禁

一个资产只有全部通过才进入 Godot：

- 设计：三视图比例、服装/结构、材质定义一致。
- 几何：无非流形/内面/破洞；轮廓和活动件正确；变形拓扑合格。
- 性能：三角面、材质槽、骨骼数、每顶点影响数、贴图尺寸符合预算；LOD 可用。
- UV/烘焙：无意外重叠、padding 足够、texel density 一致、normal/AO 无明显瑕疵。
- Rig：极限姿势不塌陷；装备、头发、裙摆无不可接受穿插。
- Animation：脚不滑，循环无跳帧，root motion 方向/距离正确，事件帧可复现。
- Engine：Godot 中材质、法线、透明、Skeleton/BoneMap、动画名、碰撞和 LOD 正确。
- Legal：来源记录完整，账号套餐与条款允许当前用途。

## 最值得先做的 2 周试点

不要先搭全自动平台。选三件真实资产：一个风格化 NPC、一把武器、一个环境模块；同一组参考图分别跑 Meshy/Tripo/Rodin。记录每阶段用时、返工次数、最终三角面/贴图/烘焙错误、绑定极限姿势、Godot 帧耗和单资产云成本。两周后按资产类型选择生成器，而不是凭宣传图选供应商。

最终把可重复步骤脚本化：文件命名、尺度/朝向、法线检查、贴图通道打包、glTF 导出、Godot import script；把需要审美和形变判断的环节保留为人工门禁。

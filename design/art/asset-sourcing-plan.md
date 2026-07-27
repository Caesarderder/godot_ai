# 美术素材检索与使用规划

> 检索日期：2026-07-27
> 来源边界：仅 Kenney 官方资产页（项目 source registry 当前唯一启用来源）
> 执行依据：[素材需求](asset-requirements.md)、[素材管理方案](../../project-a/assets/ASSET_MANAGEMENT.md)

## 1. 候选比较

| 候选 | 官方页 | 内容/格式 | 许可 | 匹配判断 | 决策 |
|---|---|---|---|---|---|
| Game Icons 1.0 | https://kenney.nl/assets/game-icons | 105 个 2D 图标，多尺寸黑白 PNG | CC0 | 暂停、目标、撤退、设置、锁定等操作语义准确；可在深色 UI 上使用白色版 | **选用最小子集** |
| Board Game Icons 1.1 | https://kenney.nl/assets/board-game-icons | 250 个 64 px 策略/棋盘图标 PNG | CC0 | 有角色、盾、铁、代币、建筑，但陶瓷和能源仍需牵强映射 | **暂缓**，避免错误语义 |
| UI Pack – Sci‑Fi 2.0 | https://kenney.nl/assets/ui-pack-sci-fi | 130 个按钮、面板、滑条 | CC0 | 科幻材质完整，但替换现有 Theme 会形成第二套面板语言，改造成本和拼贴风险高 | **拒绝整包接入** |
| City Kit (Industrial) 1.0 | https://kenney.nl/assets/city-kit-industrial | 25 个建筑/烟囱；GLB、FBX、OBJ | CC0 | 与低模灰城和地下工业叙事高度匹配；GLB 可直接进入 Godot | **选用 5 个模型** |
| Factory Kit 3.0 | https://kenney.nl/assets/factory-kit | 140 个工厂模块，含变化与动画 | CC0 | 质量与题材匹配，但本轮需求不需要整套传送带系统，包体和筛选面较大 | **列入 P1 后续** |

Kenney 官方支持页说明其资产页中的游戏素材使用 CC0，可用于商业项目，署名不是强制要求；
仍以每个包的资产页和包内许可为准：https://kenney.nl/support 。

## 2. 已选择素材

### Game Icons

保留 13 个白色 2× PNG：

`checkmark`、`exit_right`、`gear`、`home`、`locked`、`multiplayer`、`pause`、
`signal_3`、`star`、`target`、`trophy`、`warning`、`wrench`。

首轮真实使用：

| 图标 | 语义 | 位置 | 运行规格 |
|---|---|---|---|
| `pause` | 暂停战斗 | 战斗顶部控制条 | 18 px + 中文 |
| `target` | 自动/手动技能目标模式 | 战斗顶部控制条 | 18 px + 中文 |
| `exit_right` | 撤退 | 战斗顶部控制条 | 18 px + 中文 |

剩余 10 个是已明确排期的导航/状态子集，不代表必须全部常驻。后续每接入一个图标都先检查
20–24 px 剪影与文字组合，不删除中文短标签。

### City Kit (Industrial)

保留 `building_a`、`building_d`、`building_h`、`building_p`、`chimney_large` 和共享
`colormap.png`。在战斗大道两侧以四个建筑替换四个程序化方盒，烟囱放在远端轮廓区。

使用原则：

- 不改变道路宽度、单位路径或碰撞；
- 环境模型不承载玩法逻辑，仅增强工业城辨识；
- 仍保留八个程序化灰楼，避免外部素材完全主导场景；
- 建筑位于行动区外侧，Boss 峰值画面优先保证角色和炮击提示；
- 通过包装代码统一缩放和朝向，不修改上游 GLB。

## 3. 3D 人物规划

本轮没有找到能替换现有瓷甲角色且不破坏游戏身份的通用角色包，因此不下载 Kenney 通用人物。
这不是缺口遗漏，而是有意保持项目独特性。

下一阶段按以下顺序提升：

1. 复核现有 Asset Vault 来源与项目 owner；当前 manifest 已记录“usable / 无署名”，正式发布仍需
   独立检查项目整体的同人 IP 边界；
2. 补充每个模型的 AABB 和材质数量；现有 JSON 已记录 SHA-256、1,296–1,656 三角面和验证命令；
3. 统一 wrapper scene 的缩放、朝向、阵营材质和阴影策略；
4. 为 idle/attack/hit/skill/defeat 建立动画覆盖矩阵；
5. 从一致镜头生成军团页角色肖像，避免混入另一套通用人形美术。

若未来需要全新敌方阵营，再单独建立角色 brief；不得从本次环境包顺手扩张范围。

## 4. 分阶段落地

### 本提交

- 两份素材治理文档与本检索规划；
- 两个 CC0 批次的最小子集、许可证据与 SHA-256；
- 战斗控制条 3 个代表性图标；
- 战斗城市 4 栋工业建筑和 1 座烟囱；
- Godot 导入、相关测试和 Web 构建/截图验证。

### 下一轮

- 给工厂、战区、军团、行动四个导航入口接入语义图标；
- 另行生产项目专属的五种资源图标，不用错误的第三方近似图标；
- 评估 Factory Kit 中管线、货盘、储罐的最小子集；
- 完成角色 provenance 和模型性能审计；
- 真机触屏检查图标尺寸、手指遮挡和低端设备性能。

### 暂缓

- 整套 Sci‑Fi 面板替皮；
- 通用 Kenney 角色替换核心瓷甲角色；
- 大批量导入 Factory Kit；
- 只为标题页装饰而增加高分辨率背景。

## 5. 验收与回退

- 若 18 px 图标不能帮助扫视或挤压中文，回退为文字按钮但保留素材批次；
- 若工业建筑削弱单位对比，先降低饱和/亮度或替换回程序化方盒；
- 若 Web `.pck` 增量或帧时间不可接受，按“烟囱 → 两栋次要建筑 → 全部外部建筑”的顺序回退；
- 回退时更新 manifest 状态和截图，不直接删除来源记录。

# 手机端随机英雄放置远征：执行规格

## 1. Metadata

- Source: Deep Interview
- Profile: Standard
- Context: Greenfield
- Rounds: 8
- Final ambiguity: 6%
- Threshold: 20%
- Context snapshot: `.omx/context/fantasy-idle-expedition-20260717T080734Z.md`
- Transcript: `.omx/interviews/fantasy-idle-expedition-20260717T082934Z.md`

## 2. Clarity Breakdown

| Dimension | Score |
|---|---:|
| Intent | 98% |
| Desired outcome | 97% |
| Scope | 94% |
| Constraints | 78% |
| Success criteria | 96% |

## 3. Intent

制作一款手机端单机休闲放置游戏，让玩家通过随机英雄培养、队伍编成和挂机刷宝，持续获得开罗游戏式的目标感、正反馈和“这支队伍是我养出来的”成长体验。

## 4. Desired Outcome

玩家无需高频操作即可持续产出，但每次回到游戏都能做出有意义的英雄取舍、编队调整和装备选择。任务系统不断提示当前成长方向，系统强度则自然形成推进门槛。玩家能够清楚感知自己的决策带来了战力与通关能力提升。

## 5. Core Loop

1. 选择关卡或远征目标。
2. 队伍自动战斗并积累金币、培养资源和装备掉落。
3. 大任务提供阶段方向，小任务持续提示可完成动作并发放正反馈。
4. 招募随机英雄，比较职业、资质、天赋/性格与技能组合。
5. 培养英雄、调整队伍位置与搭配。
6. 筛选、装备和强化随机词条装备。
7. 轻量升级营地设施，提高招募、锻造或资源效率。
8. 依靠新的英雄/编队/装备方案跨过此前卡点，进入下一阶段。

## 6. System Priority

### P0: 随机英雄招募与培养

- 英雄是唯一运行实例，不是固定角色卡。
- 静态职业模板定义基础属性、定位、技能池和成长规则。
- 实例字段至少包括稳定 ID、随机姓名、职业、等级、经验、资质、天赋/性格、已解锁技能和装备引用。
- 首版随机维度必须可读、可比较，不能让玩家只看一个综合评分。

### P0: 队伍编成

- 玩家能从英雄池选择成员并调整位置。
- 职业定位、位置和技能目标规则必须让至少两次主动换人/换位在前 30 分钟内有真实意义。
- 首版优先清晰的前后排或槽位规则，不追求复杂棋盘。

### P1: 装备词条与强化

- 装备是刷宝惊喜和英雄构筑放大器，不取代英雄本身。
- 静态装备模板与运行装备实例分离；实例保存品质、随机词条、强化等级等。
- 前 30 分钟保证至少一次能被玩家理解的稀有装备跃迁。

### P2: 营地设施

- 首版最薄，只保留约 3 座直接服务核心循环的设施，例如酒馆、铁匠、训练场/仓库。
- 采用线性或少分支升级，提供产能、招募或强化效率。
- 营地是任务目标和节奏包装，不做复杂建造布局、人口模拟或深度经营。

### 横向骨架: 大任务与小任务

- 大任务描述阶段目标，小任务提示当前可执行成长动作。
- 任务进度由统一游戏事件驱动，不轮询，不在各业务脚本中硬编码任务逻辑。
- 任务完成提供奖励和反馈，但不得作为后续内容的硬性开关。

## 7. In Scope

- 手机端单机竖屏/横屏方向待 UI 原型确认。
- 自动战斗和离线结算。
- 随机英雄生成、培养、筛选与持久化。
- 基础编队与位置策略。
- 随机装备、词条、强化与装备管理。
- 薄层营地设施。
- 大小任务引导。
- 30 分钟首局体验切片。

## 8. Out of Scope / Non-goals

- 不做任务硬门槛。
- 不做固定角色抽卡池、重立绘、重剧情或大量专属角色内容。
- 首版不做深度营地建造与经营模拟。
- 不以复刻竞品的 91 职业或 200+ 装备规模为首版目标。
- 不照搬竞品源码、资产、数值或商标表达。
- 商业化、多语言、联网排行、公会、PvP 暂不进入首个可玩切片，除非另行确认。

## 9. Decision Boundaries

### Agent may decide, with frequent communication

- Godot 技术架构与目录结构。
- GDScript 数据结构、事件接口与存档格式。
- 首版职业、数值、掉率和任务节奏的具体初始值。
- UI 信息层级、原型布局和测试方案。

### Must ask before changing

- 核心循环。
- 英雄/编队/装备/营地的主次关系。
- 随机英雄模型。
- 美术主题与表现方向。
- 商业化方式。
- 目标平台或单机边界。

## 10. Godot Technical Direction

- Target baseline: Godot 4.x；具体版本在规划阶段确认。
- Data: 职业、技能、词条、装备模板、任务和设施配置使用只读 `Resource`。
- Runtime state: 英雄、装备、任务进度和经济状态使用可序列化实例数据；禁止直接修改共享 `.tres`。
- Simulation: 战斗采用确定性或准确定性的逻辑 Tick；画面是模拟结果的投影，避免每个单位拥有重型独立 `_process()`。
- Communication: 功能内使用直接信号，跨系统使用受控事件总线；UI 只监听状态变化，不直接修改数据。
- Mobile lifecycle: 应用暂停时立即保存；恢复时根据持久化 UNIX 时间戳计算离线收益，不依赖后台持续运行。
- Persistence: 保存稳定内容 ID 与实例字段，不保存 Node 或完整 Resource 对象；存档带 schema version 和迁移默认值。
- UI: Container 布局、Safe Area、触摸目标和移动端渲染器优先；关键列表使用复用/虚拟化策略。
- Testing: 纯 GDScript 项目优先 GUT；随机生成使用固定种子测试，经济/任务/战斗逻辑采用无场景单元测试，核心循环另做集成测试。

## 11. Testable Acceptance Criteria

### Product behavior

- 新存档 30 分钟内至少获得 8 名随机英雄。
- 玩家可理解至少两个英雄差异维度，不只依赖综合战力。
- 观察测试中，玩家主动换人或调整编队至少 2 次。
- 玩家获得至少 1 件明显改变战力或流派的稀有装备。
- 玩家依靠培养、编队或装备调整击败一次此前失败的关卡。
- 任务能引导上述行为，但跳过任务不会直接锁死内容。

### Technical behavior

- 相同随机种子生成可复现的英雄与掉落结果。
- 应用暂停触发安全存档；恢复后离线收益不重复结算。
- 英雄、装备、任务和营地数据在重启后完整恢复。
- 共享配置 Resource 不被运行实例污染。
- 任务奖励只能发放一次。
- 编队引用无效/已删除英雄时能安全修复或拒绝保存。

## 12. Assumptions and Resolutions

- Assumption: 大小任务需要强制推进才能形成目标感。
  - Resolution: 否。采用强引导与系统软门槛。
- Assumption: 四套 Meta 必须同等深度。
  - Resolution: 否。英雄与编队最深，装备次之，营地最薄。
- Assumption: 英雄价值来自固定角色内容。
  - Resolution: 否。价值来自随机组合、培养经历和玩家自己的队伍故事。

## 13. Open Confirmation Items

这些事项不阻止概念规格完成，但进入生产计划前需要继续沟通：

- 首发仅 Android，还是 Android 与 iOS 同步。
- 竖屏、横屏或可旋转布局。
- 美术主题、像素规格与角色动画预算。
- 团队人数、预算和目标上线周期。
- 买断、广告、IAP 或纯单机无商业化原型。
- 首版职业数、技能数、关卡数和装备词条数。

## 14. Skill-informed Constraints

- `docs-hunter`: 当前仓库无对应游戏底座，按绿地最小切片规划。
- `godot-brainstorming`: 先明确数据所有权、信号和场景职责，再实施。
- `godot-master`: 放置模拟应数据驱动、低频 Tick、离线时间戳结算。
- `mobile-development`: 暂停即存档，Safe Area 与 Mobile/Compatibility renderer 优先。
- `resource-pattern`: 配置 Resource 与运行实例严格分离。
- `inventory-system`: 装备使用稳定 ID，背包与 UI 信号绑定。
- `quest-system` / `economy-system`: 任务通过事件更新，奖励交给库存/经济系统发放。
- `component-system` / `ability-system`: 英雄能力组合化，运行状态由组件持有。
- `godot-testing`: 固定随机种子，验证行为契约而非内部实现。

## 15. Recommended Handoff

推荐先执行 `$plan --consensus --direct .omx/specs/deep-interview-fantasy-idle-expedition.md`，产出 PRD、30 分钟内容表、系统架构与测试规格；计划确认后，用 `$ultragoal` 建立可持续执行目标。需要多条并行实现线时再使用 `$team`。

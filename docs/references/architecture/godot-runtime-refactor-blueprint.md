---
km_id: reference.godot-runtime-refactor-blueprint
km_type: reference
domain: architecture
status: active
owner: programming
last_verified: 2026-07-27
source_of_truth:
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/scripts/slg_main.gd
  - project-a/game/scripts/content/objective_hurdle_catalog.gd
  - project-a/game/scripts/content/research_breakthrough_catalog.gd
  - project-a/game/scripts/domain/objectives/campaign_objective_projection.gd
  - project-a/game/scenes/ui/stage_detail_panel.tscn
  - project-a/game/scripts/ui/stage_detail_panel.gd
  - project-a/game/scripts/autoloads/game.gd
  - project-a/game/scripts/autoloads/save_manager.gd
validated_by:
  - godot --headless --path project-a --script res://tools/run_ui_smoke_tests.gd
  - godot --headless --path project-a --script res://tools/run_battle_tests.gd
  - godot --headless --path project-a --script res://tools/run_campaign_objective_projection_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:architecture-blueprint
  - workflow:incremental-refactor
related:
  - reference.architecture-overview
  - reference.file-ownership
  - reference.toilet-factory-technical-design
  - reference.verification-matrix
---

# Godot 运行时重构蓝图

## 目标与裁决

重构必须缩短玩家决策路径和玩法迭代周期，而非只美化目录。当前保留已经验证的确定性领域内核、
CommandExecutor 和存档边界；拒绝一次性重写 App Shell、把所有系统变成 Autoload、或把可变运行态
塞进 `.tres`。第一条已落地的纵向切片是战前关卡面板：从动态节点树拆成可预览场景，并增加战力、
推荐值、能力比和风险原因。

采用策略：

- `adapt`：沿用现有 `game/scripts/{state,domain,commands,persistence}`，逐屏提取 UI owner；
- `adapt`：保留 `Game`、`SaveManager` 两个应用生命周期 Autoload，后续收窄 API；
- `reject`：本里程碑不新增 EventBus、Service Locator、全局 UI 管理器；
- `adapt`：首章五关已用 typed `StageDefinition` Resource 承载策划高频字段并建立内容校验；
  后续角色原型、技能与设施沿用该迁移法，不把 schema 存档或战斗 session 改成 Resource。

## 目标文件树

```text
project-a/
├── scenes/screens/main.tscn                 # 应用组合根；只保留稳定 host
├── scripts/slg_main.gd                      # 迁移期 App Shell；路由与 sibling wiring
└── game/
    ├── scenes/ui/
    │   └── stage_detail_panel.tscn          # 已实现：战前判断的 editor-owned subtree
    ├── scenes/screens/
    │   └── war_zone_screen.tscn             # 已实现：章节、关卡与战前面板 owner
    │   └── battle_hud_screen.tscn            # 已实现：战术状态、技能与单位 HUD owner
    │   └── battle_result_screen.tscn         # 已实现：高光、战果与下一行动 owner
    │   └── legion_screen.tscn                # 已实现：编队比较、招募与成员成长 owner
    │   └── factory_screen.tscn               # 已实现：资源、行动、设施与建造 HUD owner
    │   └── goals_screen.tscn                 # 已实现：目标链、任务、战令与成就 owner
    │   └── title_screen.tscn                 # 已实现：存档感知标题入口与帮助/设置语义 owner
    │   └── settings_screen.tscn              # 已实现：体验偏好、本地数据与危险操作 owner
    │   └── help_screen.tscn                  # 已实现：核心循环、卡点恢复与本地数据说明 owner
    │   └── intelligence_screen.tscn          # 已实现：统一战力、风险与下一行动 owner
    │   └── blueprint_screen.tscn             # 已实现：研究分支、突破十连与节点行动 owner
    │   └── epilogue_screen.tscn              # 已实现：战役兑现与无尽延续 owner
    ├── scripts/ui/
    │   └── stage_detail_panel.gd            # 已实现：只读投影 + attack_requested
    │   └── war_zone_screen.gd               # 已实现：战区导航 + sibling signal
    │   └── battle_hud_screen.gd              # 已实现：战斗快照只读投影 + 语义操作信号
    │   └── battle_result_screen.gd           # 已实现：结算投影 + action_requested
    │   └── legion_screen.gd                  # 已实现：军团只读 view + 领域动作请求
    │   └── factory_screen.gd                 # 已实现：工厂只读 view + 建造/设施语义请求
    │   └── goals_screen.gd                   # 已实现：长期目标只读 view + 领取/导航语义请求
    │   └── title_screen.gd                   # 已实现：标题只读 view + primary/settings/help 信号
    │   └── settings_screen.gd                # 已实现：设置只读 view + setting/action 语义信号
    │   └── help_screen.gd                    # 已实现：版本只读 view + back_requested
    │   └── intelligence_screen.gd            # 已实现：WarReadinessReport 投影 + action_requested
    │   └── blueprint_screen.gd               # 已实现：研究只读 view + 分支/行动语义信号
    │   └── epilogue_screen.gd                # 已实现：战果只读 view + 延续行动语义信号
    ├── resources/definitions/               # 只读 `.tres`
    │   ├── objectives/
    │   │   └── hurdles/*.tres               # 当前里程碑：首章七段卡点定义
    │   ├── research/
    │   │   └── breakthrough/*.tres           # 当前里程碑：免费十连十张确定性奖励卡
    │   ├── stages/
    │   │   └── act_1/stage_1_1..5.tres      # 已实现：首30分钟关卡高频策划字段
    │   ├── archetypes/
    │   ├── skills/
    │   │   └── active/*.tres                # 当前里程碑：九个主动技能的玩家可读定义
    │   └── facilities/
    └── scripts/content/
        ├── objective_hurdle_definition.gd    # 当前里程碑：typed 卡点 Resource + 自校验
        ├── objective_hurdle_catalog.gd       # 当前里程碑：固定 preload、唯一 task ID 与只读 view
        ├── research_breakthrough_card_definition.gd # 当前里程碑：typed 十连卡定义
        ├── research_breakthrough_catalog.gd # 当前里程碑：固定十卡、聚合预算与保底隔离校验
        ├── active_skill_definition.gd        # 当前里程碑：稳定技能 ID、名称、效果与时机
        ├── active_skill_catalog.gd           # 当前里程碑：固定九技能、原型引用与内容校验
        ├── stage_definition.gd               # 已实现：typed Resource class + 自校验
        └── stage_definition_catalog.gd       # 已实现：固定 preload、唯一 ID 与完整性校验
```

下一批 UI 按玩家旅程拆分，而不是按控件类别拆分：`war_zone_screen`、`legion_screen`、
`battle_hud`、`battle_result_screen`。只有具备独立生命周期、可预览树或独立验证价值时才配对
`.tscn + .gd`；纯规则继续使用 `.gd`。

## 场景所有权与契约

| Owner | 创建/销毁 | 生命周期 | 公共契约 |
|---|---|---|---|
| `Main` / App Shell | 当前 screen、WorldHost、独立 UI scene | 应用会话 | 路由、注入 snapshot、连接 sibling |
| `WarZoneScreen` | 章节按钮、关卡按钮、StageDetailPanel | 战区 screen | 章节/关卡/出击三类语义请求 |
| `StageDetailPanel` | 自有 Label、ProgressBar、Button | 战区 screen 一次渲染 | `configure(...)`；`attack_requested(stage_id)` |
| `BattleHudScreen` | 阶段/炮击预警、单位 HP/能量、技能模式与操作按钮 | 单场战斗 | `configure(...)`、`apply_snapshot(...)`；暂停/技能/撤退信号 |
| `BattleResultScreen` | 胜负高光、奖励、贡献、复盘与行动按钮 | 单场结算 | `configure(view)`；`action_requested(id, payload)` |
| `LegionScreen` | 六槽阵型、职责/战力差比较、招募与成员成长 | 军团 screen | `configure(view)`；`tab_selected`、`action_requested` |
| `FactoryScreen` | 固定资源条、行动/设施/建造互斥 HUD、3D 交互留白 | 基地 screen | `configure(view)`；`panel_selected`、`action_requested` |
| `GoalsScreen` | 大中小目标、当前卡点、战役进度、任务、战令和成就 | 目标 screen | `configure(view)`；`tab_selected`、`action_requested` |
| `TitleScreen` | 存档摘要、下一目标和开始/继续/终章入口 | 标题 screen | `configure(view)`；`action_requested` |
| `SettingsScreen` | 体验偏好、试玩报告、备份恢复和二次删档呈现 | 设置 screen | `configure(view)`；`setting_changed`、`action_requested` |
| `HelpScreen` | 核心循环、首章卡点、成长路线、操作和本地数据说明 | 帮助 screen | `configure(view)`；`back_requested` |
| `IntelligenceScreen` | 当前编队战力、关卡能力比、无损规则、后勤短板和下一行动 | 情报 screen | `configure(view)`；`action_requested` |
| `BlueprintScreen` | 四条研究分支、一次性突破十连、当前分支两级节点与领取结果 | 科技蓝图 screen | `configure(view)`；`branch_selected`、`action_requested` |
| `EpilogueScreen` | 第一幕叙事兑现、永久战果、无尽前线与里程碑入口 | 战役尾声 screen | `configure(view)`；`action_requested` |
| `Game` Autoload | 当前 `GameState`、CommandExecutor | 应用 | 查询快照、执行领域命令 |
| `SaveManager` Autoload | 存档 adapter | 应用 | 有界加载/发布/备份；不持有 UI Node |
| `BattleSession` | 确定性战斗运行态 | 单场战斗 | tick、command、snapshot、result |

信号方向：

```text
StageDetailPanel --attack_requested(stage_id)--> App Shell
App Shell --direct command--> Game / BattleSession
Game/BattleSession --snapshot/result--> App Shell --> UI scenes
```

UI 不直接修改 `GameState`；领域层不查找 UI。重建 screen 时由 App Shell 创建并连接一次，
销毁 scene 即释放连接。

主动技能即时反馈切片沿用现有三个 owner，不增加 `.tscn`、Resource 或 Autoload：

```text
BattleSession accepted events
  --Array[Dictionary] same-tick facts--> BattleWorld (3D / audio presentation)
  --battle_events_applied(detached events)--> App Shell (connect once per battle scene)
  --direct apply_battle_events(...)---------> BattleHudScreen (short queued result copy)
```

| Signal | Emitter | Connected by | Receiver | Payload | Lifetime rule |
|---|---|---|---|---|---|
| `battle_events_applied(events: Array[Dictionary])` | `BattleWorld` | App Shell | App Shell → `BattleHudScreen.apply_battle_events` | 仅包含技能施放的确定性 tick 已接受事件深拷贝；不含 Node | 每个 `BattleWorld` 创建后连接一次，战斗 screen 销毁时随 owner 释放 |

HUD 只汇总事件中已经给出的实际技能伤害、护盾、治疗、复活、控制、召唤和策反；不得从技能 ID
重演战斗公式。Boss 炮击预警始终高于一般技能结果，避免反馈遮住下一次生存判断；多个同 tick
技能结果进入短队列逐条显示，普通攻击 tick 不发此信号，避免把 5Hz 战斗流变成高频事件总线；
减少动态模式仍保留文字确认。实现顺序是先证明本地信号携带 detached
事件，再验证 HUD 真实汇总，最后跑首章战斗和 844×390 截图。

## Resource、运行态与 Autoload

| 数据 | Godot 形式 | 规则 |
|---|---|---|
| 关卡/原型/技能/设施定义 | typed `Resource` + `.tres` | 运行时只读；固定 preload 或 allowlist load |
| Catalog 索引 | typed Resource 或静态只读 catalog | 稳定 ID；启动校验重复 ID、缺失引用和范围 |
| `GameState` / save candidate | `RefCounted` / 有界 JSON snapshot | 权威可变态；不得写回 `.tres` |
| `BattleSession` | `RefCounted` | 单场 owner；不得进入 Autoload |
| `CampaignObjectiveProjection` | `RefCounted` 静态只读投影 | 从持久状态、引导 snapshot 与 `WarReadinessReport` 生成跨页面一致的大/中/小目标；不得成为 Autoload |
| 首章卡点定义 | `ObjectiveHurdleDefinition` typed Resource + 七个 `.tres` | 运行时共享只读；只承载稳定 task ID、大小坎、原因和过坎办法 |
| 首章行动任务与目标条件 | `OnboardingTaskDefinition` / `OnboardingObjectiveDefinition` typed Resource + 七个任务、十个目标 `.tres` | 运行时共享只读；定义任务顺序、玩家文案、CTA、完成条件与奖励预算，不保存完成进度 |
| 免费研究突破配方 | `ResearchBreakthroughCardDefinition` typed Resource + 十个 `.tres` | 运行时共享只读；恰好两名永久援军与八张研究物资，服务按定义原子发奖 |
| 主动技能玩家定义 | `ActiveSkillDefinition` typed Resource + 九个 `.tres` | 运行时共享只读；稳定 ID 继续供战斗逻辑使用，名称、职责、实际效果和释放时机供 UI 投影；不保存等级、能量、冷却或伤害运行态 |
| UI view model | duplicate-safe Dictionary，后续按压力升级 typed value | 只读投影；不得保存 Node 引用 |
| 本地试玩心流证据 | `LocalPlaytestJournal` 有界 JSON + 导出派生指标 | 默认关闭、仅白名单相对时间与语义动作；不联网、不记录 payload、角色 ID、设备或账号标识 |

Autoload DAG 当前为 `SaveManager → AppBootstrap ← Game`：`SaveManager` 和 `Game` 先注册，
最后注册的 `AppBootstrap` 是唯一组合根，显式把保存服务注入 Game 并幂等初始化。`Game._ready()`
不再查找 sibling，也不依赖 sibling `_ready()` 完成业务初始化。当前不合并成巨型
`AppServices`。跨页面音乐由不会随 screen sibling 重建的 App Shell 子场景
`MusicDirector.tscn` 持有，已足以保持连续性和浏览器解锁状态，因此不提升为 Autoload；
只有未来出现脱离 App Shell 的真实跨主场景生命周期需求时才重新评估。
当前入口 `slg_main.gd` 只调用 Game 的备份、预览、恢复和重置窄接口，不再查找
`/root/SaveManager` 或把保存服务对象穿过 UI。

当前卡点 Resource 迁移的所有权脊柱为：

```text
ObjectiveHurdleDefinition .tres
  --fixed preload/validate--> ObjectiveHurdleCatalog
  --duplicate-safe view-----> CampaignObjectiveProjection
  --same hierarchy view-----> GoalsScreen / FactoryScreen / TitleScreen
```

此路径没有运行时信号：定义是只读查询，玩家事件仍由 `OnboardingService` 消费并写入
`GameState.onboarding`，完成/奖励仍由 `CommandExecutor` 幂等提交。Resource 不保存进度、不引用
Node，Catalog 不注册 Autoload；App Shell 重建页面时重新推导 view，因此不存在重复连接或陈旧引用。

首章行动任务迁移的所有权脊柱为：

```text
10 × OnboardingObjectiveDefinition .tres
  --references---------> 7 × OnboardingTaskDefinition .tres
  --fixed preload/validate--> OnboardingDefinitionCatalog
  --detached Dictionary view--> OnboardingCatalog compatibility facade
  --event matching/progress--> OnboardingService + GameState.onboarding
  --claim-once reward-------> CommandExecutor
```

目标定义只描述一个自然行为证据及其玩家 CTA；任务定义只组合目标、教学文案和显式非负奖励字段。
Catalog 必须锁定七个任务、十个目标、稳定顺序和唯一 ID，并在内容异常时 fail closed。
`OnboardingCatalog` 保留既有 Dictionary API，避免一次性改写服务、UI 与存档追赶逻辑；返回值始终
深复制，调用者不能修改共享 Resource。此路径不增加运行时信号：玩家事件仍由
`OnboardingService` 消费并写入 `GameState.onboarding`，奖励仍由 `CommandExecutor` 在持久命令内
原子结算，Resource 不保存进度、不引用 Node、不注册 Autoload。

免费十连的所有权脊柱为：

```text
10 × ResearchBreakthroughCardDefinition .tres
  --fixed preload/budget validation--> ResearchBreakthroughCatalog
  --read-only definitions-----------> ResearchBreakthroughService
  --one durable command transaction-> GameState candidate + receipt
  --detached result event-----------> BlueprintScreen
  --semantic CTA--------------------> LegionScreen first-formation flow
```

卡定义不生成角色、不修改钱包、不持有 pity 或 Node；Catalog 只校验恰好十张、两名指定 A 级援军、
八张资源、聚合资源预算和唯一 card ID。`ResearchBreakthroughService` 是唯一发奖 owner，失败时
不发布 candidate；`CommandExecutor` 仍负责 revision、业务键、保存与 receipt。结果页和首次编队
场景只消费 detached event/view，页面重建不会重复发奖或推进长期招募保底。

首章真人心流证据的所有权脊柱为：

```text
App Shell semantic screen / command / battle-input facts
  --opt-in bounded record--> LocalPlaytestJournal
  --derive only on read----> 12-milestone funnel + non-battle gap
                              + manual-battle decision gap
  --detached JSON download-> observer / neutral post-session interview
```

App Shell 只发布“进入页面、命令成功/失败、开战/结算、技能请求是否被接受、手动/自动切换、
暂停/恢复、撤退”等语义事实，不发布命令 payload、永久角色 ID 或节点引用。Journal 是普通
`RefCounted`，由 App Shell 持有且默认关闭；自动技能和暂停区间不得被计入手动战斗无输入时长。
派生指标只用于定位录像中的迷路、误触和 90 秒停滞，不能代替玩家对目标理解、乐趣和继续意愿的
中立访谈，也不能晋升为联网遥测或应用级 Autoload。

首章后技能芯片转化的所有权脊柱为：

```text
LogisticsService active-skill cost table
  --same cost query-------> App Shell detached hero growth view
  --exact cost/status-----> LegionScreen roster card
  --player command-------> CommandExecutor
  --atomic validation-----> LogisticsService research_active_skill
```

成本只能由领域层定义一次，UI 不复制数值或自行判断余额。首章 Boss 前的专注成长仍只允许已验证的
冲锋/装甲二星路线，避免技能研究抢走通关必需材料；Boss 后“先培养军团”直接进入角色成长页，
把已经获得的芯片、技术和工厂材料显示为一个可比较的自主成长选项。此路径不自动消费奖励、不新增
任务硬锁，也不通过弹窗打断第二章侦察。

主动技能内容的所有权脊柱为：

```text
FactoryCatalog archetype --stable active_skill ID--> ActiveSkillCatalog fixed preload
BattleSession -----------same stable ID-----------> deterministic combat rule
ActiveSkillCatalog -------detached player view----> App Shell
App Shell ----------------display fields----------> LegionScreen / BattleHudScreen
```

`ActiveSkillCatalog` 必须校验恰好九个唯一技能、每个 `FactoryCatalog` 原型都能解析到定义且
`archetype_id` 反向一致；未知 ID 失败关闭并返回空 view。UI 不显示内部 ID，也不自行解释战斗公式。
`BattleSession` 仍是伤害、目标、星级分支和事件的唯一权威，Resource 只用与当前实现一致的玩家语言
解释“做什么、何时用”。此切片不新增场景或 Autoload：现有 App Shell 是定义查询与 screen view
组装 owner，screen 重建时只消费 detached Dictionary，因此没有新增信号或重复连接生命周期。

## 本地无障碍与焦点合同

当前玩家 UI 的可交互集合按 Godot 类型定义，不按控件命名或某几个已知页面硬编码：

- `BaseButton`、`Slider`、`LineEdit` 与 `TextEdit` 必须使用 `FOCUS_ALL`；
- authored scene 与运行时生成控件必须各自拥有可见焦点反馈。按钮使用高对比 `focus`
  StyleBox；Slider 依据 Godot 4.6 的真实主题合同使用 `grabber_area_highlight`，使键盘/手柄焦点
  不只依赖默认 grabber 纹理或颜色猜测；
- 页面打开后把焦点交给当前主行动；自动空间导航至少能从当前控件移动到另一个可用控件，
  不允许焦点卡死在隐藏、禁用或已释放节点；
- 风险、胜负、能量、炮击与资源不足必须同时提供文字、图形或数值语义，不能只靠红/绿颜色；
- “减少动态”只移除脉动、位移和震屏，保留命中、预警、技能结果和结算文字；
- 屏幕阅读器语义与浏览器辅助技术仍是外部真机门禁，本地焦点、字体覆盖和静音可读不能冒充它。

验证清单由 `game/scenes/screens/*.tscn` 加 `StageDetailPanel` 的固定 preload 构成；新增 authored
screen 时必须同步加入。测试需递归审计所有交互类型和动态 CTA，而不是以旧的“七个场景”数量
宣称覆盖。焦点、字体、减少动态与 48 CSS 像素触控目标是四条独立证据。

Web 集成还必须证明导出包的 Canvas 真正接收键盘事件：在标题响应式布局稳定并由
`TitleScreen` 把焦点交给主 CTA 后，Chrome smoke 使用真实 `Enter` 激活“开始/继续战役”；
后续设置、备份、导入与离线 PWA 流程继续使用触控。只有两条输入路径在同一候选中共存通过，
才可声称 Web 键盘基线没有破坏手机触控主链；这仍不等于真实手柄或屏幕阅读器设备验证。

## 资产治理

- 全局字体、共享 UI 主题放 `assets/fonts`、未来 `game/ui/themes`；feature-only 资产随 feature；
- GLB 通过本地 wrapper scene 进入运行时，业务脚本不依赖导入器生成的内部节点名；
- 每个外部资产保留来源、作者、许可证、下载日期和修改记录；发布时汇总到 LICENSES；
- 路径使用 `snake_case`，固定依赖用 `preload`；数据驱动加载只能解析允许的 `res://` 前缀并校验类型；
- `artifacts/` 是验证证据，不是游戏运行资产，不得进入玩法加载路径；
- Web 发布分别验证首次 payload、导入产物、峰值内存、音频解锁和离线缓存。

### Web 存储失败关闭合同

浏览器允许加载 WebAssembly 不等于允许 IndexedDB。发布验证必须把三种状态分开：

1. 正常来源存储：`user://` 写入、刷新和重新启动后保持同一存档；
2. 私密会话存储：同一会话可用但关闭上下文后丢弃，UI 不得宣称长期持久；
3. 完全阻断存储：在页面脚本运行前拒绝 `indexedDB`，游戏若仍能启动只能作为非持久会话，
   设置页必须显示备份警告；任何领域命令若保存失败，不得交换 live state，并必须显示可恢复错误。

第三种验证必须使用隔离浏览器 profile，并在文档启动前注入阻断，不能在 Godot 已打开数据库后
删除对象来冒充失败。若引擎因平台限制无法启动，应把它记录为明确的浏览器兼容门禁，不能用
headless `FileAccess` 失败测试代替真实 Web 结论。测试工具属于 `tools/`，继续由 Web preset 排除，
不新增 Autoload、运行时服务或遥测字段。

当前八个马桶人 GLB 均由 `game/scenes/actors/ally_models/*_model.tscn` 包装，
`ToiletUnitView` 只 preload wrapper。`artifacts/` 与 runtime 路径的反向搜索为空。

## 迁移顺序与门禁

1. 每次先用现有 smoke/领域测试固定行为。
2. 提取一个玩家可见 owner，App Shell 只保留构建参数和连接。
3. 新 scene 必须可独立实例化，且集成 smoke 覆盖玩家文字/CTA。
4. 先为一个 catalog 引入 typed definition 和内容校验，再迁移其调用者。
5. 搜索确认旧构建函数无调用后再删除，不做横跨全部 screen 的大爆炸迁移。
6. 每刀通过编辑器解析、focused tests、844×390 与窄屏视觉证据；关键流程再跑浏览器。

十三块 UI 与首个内容切片完成证据：`StageDetailPanel`、`WarZoneScreen`、`BattleHudScreen`、
`BattleResultScreen`、`LegionScreen`、`FactoryScreen`、`GoalsScreen`、`TitleScreen` 与
`SettingsScreen`、`HelpScreen`、`IntelligenceScreen`、`BlueprintScreen` 与
`EpilogueScreen` 已拥有 authored
scene tree、延迟 configure 生命周期和单向语义信号；UI smoke、battle tests 与真实 844×390
截图通过。首章 Boss 首屏可读到战力差、风险及两条已验证路线；结算首屏可读到奖励、高光、
按永久角色 ID 统计的核心贡献、巨炮表现和下一行动。首章五关的推荐战力、倍率、Boss 耐久和
战前文案已由五个 typed `.tres` 提供，并通过专用内容校验与 98 场扫描。Autoload 与资产边界
也已收口。`LegionScreen` 接管旧动态军团树后，headless UI smoke 与 Compatibility capture
退出时原有的 CanvasItem、字体和纹理泄漏同时消失。`FactoryScreen` 进一步接管固定资源条、
首章行动、设施详情和三步网格建造，而 App Shell 只保留 3D 世界、镜头/射线、选格和命令路由。
`GoalsScreen` 已接管大/中/小目标、大小卡点、行动任务、30 级战令与永久成就；App Shell 只投影
只读 view 并路由领域命令。
`TitleScreen` 进一步接管存档感知的摘要、下一目标和三项入口；App Shell 只生成进度 view、
播放统一点击反馈并路由到基地、设置或帮助。
标题、基地“前线来电”和目标中心不再各自判断章节完成与下一行动：
`game/scripts/domain/objectives/campaign_objective_projection.gd` 作为纯 `RefCounted` 投影 owner，
组合 `OnboardingService` snapshot、当前关卡与 `WarReadinessReport`，统一产出标题目标、基地任务、
大/中/小目标、挑战线缺口和语义 CTA。它没有 Node、信号或可变全局状态，因此不提升为 Autoload；
App Shell 只把同一投影拆给各 authored scene。聚焦状态矩阵同时覆盖首章进行中、第二章需培养和
达到挑战线后的侦察恢复。
`SettingsScreen` 接管双栏布局、偏好控件、本地数据状态、导入预览和危险操作确认呈现；
App Shell 只投影现有 `SettingsStore` / Web 能力、执行持久化与浏览器文件动作并处理返回路由。
`HelpScreen` 把 1-4 设计卡点、研究所免费突破十连、冲锋/装甲两条路线、战后完全恢复、
行动目标梯和本地数据边界收进可回看的双栏档案；App Shell 只注入版本并按进入来源返回。
`IntelligenceScreen` 接管统一战情仪表盘，只消费 `WarReadinessReport`，同时呈现当前编队
`CombatPower`、关卡能力比、风险原因、无损出征、后勤短板与唯一 CTA；App Shell 只生成报告并
路由到军团培养或目标关卡。
`BlueprintScreen` 接管四条研究分支、研究所解锁后的免费突破十连、结果回显与当前分支两级
节点；免费十连明确不消耗招募券且不推进长期保底，App Shell 只投影权威状态并路由开始、领取、
军团查看和返回命令。
`EpilogueScreen` 接管第一幕完成后的叙事兑现、25 城占领、永久角色与军团养成总结，并把
“挑战无尽前线、刷新军团极限”设为新的大目标；App Shell 只计算战果投影并路由无尽、里程碑
和基地三个延续行动。
九个主动技能已迁入 `ActiveSkillDefinition` typed Resource 与固定 preload Catalog；军团培养页
显示中文技能名、职责、实际效果和最佳时机，战斗技能卡显示“角色 · 技能名”并携带同源时机提示。
稳定内部 ID 仍只用于 `FactoryCatalog`、存档引用和 `BattleSession` 确定性规则，不再泄漏给玩家。
`BattleResultScreen` 在首章引导未完成时优先使用 `OnboardingService.snapshot()` 的下一真实
行动；1-4 反攻后以“选择工业支援”进入工厂，并隐藏重复的通用工厂按钮，直到设施投产、后勤
收取和援军升星完成后才把 1-5 暴露为主 CTA。

主动技能的玩家文案与确定性公式保持分层：`ActiveSkillDefinition.tres` 拥有稳定 ID、职责、效果
和时机说明，`BattleSession` 拥有伤害、护盾、目标选择和事件。仅对跨多个调用点、必须进入平衡
回归的公式系数使用具名 basis-point 常量；不把单个技能的运行时公式塞进 UI Resource，也不让
UI 按文案重演伤害。G-Man 使用 `GMAN_OVERRUN_BASE_DAMAGE_BP` 作为通用倍率；只有明确需要
power fantasy 的关卡可以通过 StageCatalog 的 `gman_opening_damage_bp` 提高该场第一次号令。
运行时单位只保存本局 `skill_casts`，不进入永久存档；事件和 snapshot 可携带该事实但 UI 不
据此重算。当前仅 1-1 使用 30000bp，其余和重复施法均为 20000bp；修改必须同时通过首技能有效
伤害、7-seed 首章扫描和 14 条干净新档旅程，不能只因截图数字更大而调整。

## 战斗镜头与当前目标投影

`BattleWorld` 是战斗 `Camera3D` 和世界内目标强调的唯一 owner。它每帧只读取一次
`BattleSession.snapshot()`，从当前阶段第一个存活敌人或结构推导表现目标，再把永久存活友军前线
与目标共同放入画面；远距离目标必须先截断到有限预览距离，避免镜头越过玩家军团或突然跳向尚未
交战的远景。镜头使用与帧率无关的指数趋近并限制单帧 delta，震动只叠加在基础机位之后。

目标强调复用一个 `BattleTargetMarker` 节点：落在当前目标脚下的金色双环与朝向箭头共同表达
“正在攻击这里”，不可只依赖颜色；切换阶段或目标时更新位置，战斗清理时一并释放。标记不写回
领域状态、不自行选敌、不预测伤害，也不参与物理、导航、命中或胜负。低画质保留轮廓，减少动态
模式保留静态形状并关闭脉动。首战 844×390 验收必须同时看到至少一个永久友军和当前存活目标，
二者不得被顶部目标条或底部技能卡遮挡；玩家应能在两秒内说出“我是谁、正在打谁、向哪里推进”。

```text
BattleSession snapshot (read-only)
        |
        +--> BattleWorld target projection --> one reusable world marker
        |
        +--> BattleWorld camera framing ----> Camera3D presentation only

BattleSession deterministic target/damage/result <--- no presentation dependency
```

战场视觉命题是“冷灰废墟衬托青色我方军团与橙红敌方工事，让玩家先看到推进关系，再读文字”。
三个层级只使用 Compatibility 可用的基础 Mesh、`StandardMaterial3D` 与少量 emission：

- 背景城市、路面与瓦砾使用低饱和冷灰，保持轮廓但降低明度竞争；
- 当前及后续敌方结构保持实体暗色体块，并在朝向进攻方的立面增加橙红识别条和结构类型灯，
  使“可摧毁目标”不再与背景楼体同色；
- 我方零号永久角色拥有一个常驻青色双形状指挥环，名称使用玩家可读显示名；其他友军不重复
  常驻标记，避免六人编队形成发光噪声。

颜色不是唯一编码：敌方目标同时使用立面条带/灯，指挥官使用地面环/显示名，当前目标仍使用
更大的金色双环/方向箭头。三者不得改变碰撞、选敌、伤害或输入区域，不新增局部灯、实时阴影、
透明排序依赖或高级渲染路径。低画质保留单层形状和文字；减少动态只关闭脉动，不移除语义。

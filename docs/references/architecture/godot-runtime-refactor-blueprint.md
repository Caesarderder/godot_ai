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
    │   ├── stages/
    │   │   └── act_1/stage_1_1..5.tres      # 已实现：首30分钟关卡高频策划字段
    │   ├── archetypes/
    │   ├── skills/
    │   └── facilities/
    └── scripts/content/
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

## Resource、运行态与 Autoload

| 数据 | Godot 形式 | 规则 |
|---|---|---|
| 关卡/原型/技能/设施定义 | typed `Resource` + `.tres` | 运行时只读；固定 preload 或 allowlist load |
| Catalog 索引 | typed Resource 或静态只读 catalog | 稳定 ID；启动校验重复 ID、缺失引用和范围 |
| `GameState` / save candidate | `RefCounted` / 有界 JSON snapshot | 权威可变态；不得写回 `.tres` |
| `BattleSession` | `RefCounted` | 单场 owner；不得进入 Autoload |
| `CampaignObjectiveProjection` | `RefCounted` 静态只读投影 | 从持久状态、引导 snapshot 与 `WarReadinessReport` 生成跨页面一致的大/中/小目标；不得成为 Autoload |
| UI view model | duplicate-safe Dictionary，后续按压力升级 typed value | 只读投影；不得保存 Node 引用 |

Autoload DAG 当前为 `SaveManager → AppBootstrap ← Game`：`SaveManager` 和 `Game` 先注册，
最后注册的 `AppBootstrap` 是唯一组合根，显式把保存服务注入 Game 并幂等初始化。`Game._ready()`
不再查找 sibling，也不依赖 sibling `_ready()` 完成业务初始化。当前不合并成巨型
`AppServices`；若后续跨场景音频连续性和浏览器解锁证明
需要应用生命周期，才将 AudioDirector 提升为有持久播放器子树的 Autoload scene。
当前入口 `slg_main.gd` 只调用 Game 的备份、预览、恢复和重置窄接口，不再查找
`/root/SaveManager` 或把保存服务对象穿过 UI。

## 资产治理

- 全局字体、共享 UI 主题放 `assets/fonts`、未来 `game/ui/themes`；feature-only 资产随 feature；
- GLB 通过本地 wrapper scene 进入运行时，业务脚本不依赖导入器生成的内部节点名；
- 每个外部资产保留来源、作者、许可证、下载日期和修改记录；发布时汇总到 LICENSES；
- 路径使用 `snake_case`，固定依赖用 `preload`；数据驱动加载只能解析允许的 `res://` 前缀并校验类型；
- `artifacts/` 是验证证据，不是游戏运行资产，不得进入玩法加载路径；
- Web 发布分别验证首次 payload、导入产物、峰值内存、音频解锁和离线缓存。

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
`BattleResultScreen` 在首章引导未完成时优先使用 `OnboardingService.snapshot()` 的下一真实
行动；1-4 反攻后以“选择工业支援”进入工厂，并隐藏重复的通用工厂按钮，直到设施投产、后勤
收取和援军升星完成后才把 1-5 暴露为主 CTA。

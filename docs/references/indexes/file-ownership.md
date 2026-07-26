---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-26
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/implementation-status.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/quest/quest_service.gd
  - project-a/game/scripts/domain/achievement/achievement_service.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - manual-design-integrity-review-2026-07-26
  - rg --files project-a
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - decision.project-a-web-3d-root
  - map.domains
---

# 文件归属索引

> `project-a/` 是当前 Godot Web-first 3D 实现根。现有路径承载旧永久英雄版本；新重构优先在现有领域目录内替换所有权，不另建平行内核。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `project-a/project.godot` | platform | 引擎、启动场景、renderer、viewport | present / Compatibility |
| `project-a/scenes/screens/main.tscn` | presentation | App Shell 组合根：WorldHost + CanvasLayer | present / headless smoke |
| `project-a/scripts/slg_main.gd` | application-shell | 标题、设置、存档备份、基地、目标、军团、出征、战斗 HUD 与结算生命周期 | present / 844×390 design canvas + capture |
| `project-a/export_presets.cfg` | release | 单线程 Web/PWA 导出、离线页、图标与移动 head 元数据 | implemented / local release candidate |
| `project-a/game/resources/definitions/**` | content | 只读职业、技能、装备、关卡等 `.tres` | 首章五关 StageDefinition present；其余 planned |
| `project-a/game/scripts/state/**` | domain-kernel | 可序列化 schema v4 GameState、英雄、六槽编队、经济、工厂、任务与成就状态 | present / Meta headless tests |
| `project-a/game/scripts/commands/**` | application | CommandExecutor、fingerprint、幂等、revision 与事务编排 | present / Meta headless tests |
| `project-a/game/scripts/domain/recruitment/**` | domain-kernel | 固定 seed 英雄生成 | present / Meta headless tests |
| `project-a/game/scripts/domain/recruitment/research_breakthrough_service.gd` | domain-kernel | 研究所落成后一次性免费十连、两名确定性援军和长期保底隔离 | present / focused breakthrough tests |
| `project-a/game/scripts/domain/progression/**` | domain-kernel | L1-L5 培养与派生属性 | present / Meta headless tests |
| `project-a/game/scripts/domain/factory/**` | domain-kernel | 三材料八配方、生产队列、领取生成英雄、同原型同星 3 合 1 | present / Meta headless tests |
| `project-a/game/scripts/domain/formation/**` | domain-kernel | 固定六槽 2×3 编队校验 | present / Meta headless tests |
| `project-a/game/scripts/domain/battle/**` | domain-kernel | 5Hz 三阶段攻城、六人推进、技能、核心巨炮与胜负 | present / battle headless tests |
| `project-a/game/scripts/domain/quest/**` | domain-kernel | 25 大战役任务、3 槽循环小任务、战功等级、任务领取 | present / Meta + UI smoke |
| `project-a/game/scripts/content/objective_hurdle_*.gd`、`project-a/game/resources/definitions/objectives/hurdles/**` | authored-content | 首章大小卡点 typed 定义、固定索引与内容校验；不持有运行进度 | present / definition + projection tests |
| `project-a/game/scripts/domain/achievement/**` | domain-kernel | 24 个永久一次性成就、可靠回填、event key 去重、成就领取 | present / Meta + UI smoke |
| `project-a/game/scripts/domain/{equipment,idle}/**` | domain-kernel | 装备、离线规则 | absent / deferred |
| `project-a/game/scripts/persistence/**` | persistence | 严格 JSON schema、2 MiB 上限、candidate writer、主档/备份与导入恢复 | present / Meta headless tests |
| `project-a/game/scripts/platform/local_playtest_journal.gd` | platform-evidence | 显式 opt-in、白名单本地事件、256 条上限、首章 12 里程碑/分段耗时/断点/停滞派生、报告导出与关闭删除 | present / Platform + Chrome smoke |
| `project-a/game/scripts/autoloads/{save_manager,game,app_bootstrap}.gd` | application | 保存服务、游戏状态/命令、显式应用组合根 | present / bootstrap + lifecycle tests |
| `project-a/game/scripts/platform/web/**` | platform | visibility、持久性探测、音频解锁、Web bridge | absent / M0-M1 |
| `project-a/game/scripts/presentation_3d/**` | presentation | 程序化马桶人、结构目标和战斗 snapshot/event 的 3D 投影 | present / runtime smoke + capture |
| `project-a/game/{scenes/presentation,scripts/presentation}/music_director.*` | audio-presentation | 双 Stream 播放器、可取消淡化、路线音乐状态、后台暂停与独立音量 | present / MusicDirector + UI + Web smoke |
| `project-a/game/scenes/actors/ally_models/**` | asset-integration | 八个项目自有 GLB wrapper，隔离导入器子树与运行时变换 | present / asset 3D tests |
| `project-a/game/scripts/ui/**` | presentation | 可复用独立 UI 场景/组件 | 战前面板、战区、战斗 HUD、结算、军团、工厂与目标中心 present；其余主要 UI 仍在 App Shell |
| `project-a/game/scenes/**` | presentation | app、battle_3d、screens、dialogs、ui | 战前面板、完整战区、战斗 HUD、结算、军团、工厂与目标 screen present；其余 planned |
| `project-a/tools/run_meta_tests.gd` | independent-verifier | Meta、命令、存档、任务、成就和 bootstrap headless tests | present / passing |
| `project-a/tools/run_battle_tests.gd` | independent-verifier | 六人三阶段攻城、技能、核心炮、结构事件、确定性、超时与 result-once | present / passing |
| `project-a/tools/capture_*.gd` | visual-verifier | 标题、战斗和关键操作反馈的确定性截图入口 | present / desktop GL Compatibility；装甲格挡反震 844×390 evidence |
| `project-a/tests/**`、其余 `project-a/tools/**` | independent-verifier | GUT、内容校验、seed、经济、Web smoke | absent / Test Spec §3 |
| `taptap/**` | historical-reference | 旧 UrhoX Lua 2D 可玩原型 | present / 非当前交付 |

## 新 SLG 重构的 planned ownership

| 目标责任 | 优先落点 | 必须拥有 |
|---|---|---|
| 工业与战争经济账本 | `state/economy_state.gd`、`domain/economy/**`、`commands/**` | 三工业资源、金币、工业技术、突破资源、reason code 与对账 |
| 永久角色成长 | `state/hero_state.gd`、`domain/progression/**` | hero ID、等级、经验、星级、技能、派驻与战备度 |
| 设施与离线生产 | `state/factory_state.gd`、`domain/factory/**` | 设施、产速、容量、加工、时间回拨保护与领取 |
| 六人编队 | `state/formation_state.gd`、`domain/formation/**` | 1–6 人 2×3、唯一角色引用、零战备拒绝 |
| 伤损与战果结算 | `domain/battle/**`、`commands/**`、autoload application | 撤退、damage/xp/reward manifest、exact-once 与城镇进度 |
| 维修 | 目标 `domain/repair/**` 或 `domain/factory/**` 中唯一 owner | 快速、完全、计时维修、槽位和最低恢复 |
| 任务与里程碑 | `domain/quest/**`、状态与 catalog | 金币、工业技术、角色碎片、Boss 核心与目标进度 |
| 长期进度与招募 | `state/meta_progression_state.gd`、`domain/meta/**`、`domain/recruitment/signal_recruit_service.gd` | 指挥官等级、日周任务、免费战令、永久成就、招募概率与保底 |
| 存档迁移 | `persistence/**` | v6 golden save、新 schema、备份、回滚和 legacy wallet |
| UI 投影 | `scripts/main.gd` 后续拆分的 `ui/**` | 工厂、军团、战区、目标、维修、战前和结算 view model |

以上均是 planned ownership。当前 `blueprint_draw_service.gd`、`run_factory_casualty_tests.gd` 和
研发/科技/补位 UI 属于 v6 迁移输入，不是新 SLG 实现证据。

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files project-a`、Godot headless tests、Web release export 和浏览器 smoke 确认；路径存在并经实际验证后，才把 `absent` 改为真实入口。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。

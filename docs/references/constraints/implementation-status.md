---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-25
source_of_truth:
  - README.md
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/quest/quest_catalog.gd
  - project-a/game/scripts/domain/quest/quest_service.gd
  - project-a/game/scripts/domain/achievement/achievement_catalog.gd
  - project-a/game/scripts/domain/achievement/achievement_service.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/game/scripts/platform/settings_store.gd
  - project-a/game/scripts/platform/web_runtime.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
  - project-a/tools/run_campaign_tests.gd
  - project-a/tools/run_platform_tests.gd
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - godot --headless --path project-a -s tools/run_campaign_tests.gd
  - godot --headless --path project-a -s tools/run_platform_tests.gd
  - local-http-844x390-title-settings-camp-campaign-battle
tags:
  - reference:implementation-status
  - risk:planned-not-implemented
related:
  - reference.file-ownership
  - quality.stale-docs
  - decision.return-to-project-a
---

# 实现状态基线

## 目标

防止知识地图把批准规划误写成已经实现的系统。

## 事实

- 当前开发根是 `project-a/`，使用 Godot 4.6.3、GDScript 和 3D 表现，目标为 Web-first、手机浏览器优先。
- 项目已切换到 Compatibility renderer；主场景现为长期存在的 App Shell，承载标题、营地、工厂、培育、六人编队、出征确认、战斗 HUD、技能按钮、自动技能开关与结算 UI。
- v4 Meta 领域内核已落地：可序列化 `GameState` schema 4 / content `factory-siege-v4`、固定 seed 初始 8 英雄、四职业/八原型/四资质/特质、星级、L1-L5 培养、六槽编队、经济资源、工厂材料、蓝图锁定/解锁、生产队列、自动技能偏好、任务、成就、命令 fingerprint/幂等/revision/先存后换、严格 JSON schema、v1/v2/v3->v4 迁移、主档/备份恢复和启动加载。
- 新档基线为 8 名英雄、有效六槽编队、250 金币、2 本经验书、120 瓷、100 零件和 80 污泥；英雄、编队、培养、工厂、合成、命令与存档契约由 `project-a/tools/run_meta_tests.gd` headless 验证。
- 第一幕 25 关现已数据化落地：`StageCatalog` 定义五章、每章五关、章节敌军梯度、结构 Boss、奖励、蓝图解锁与顺序推进；每关同时提供威胁摘要、反制提示、章节反馈和蓝图解锁预览，普通关、Boss 关与章节收束文案有可读差异。出征界面提供章节地图、锁定/通关/选中状态、掉落预览、阵容与上述战术信息。`run_campaign_tests.gd` 会遍历全部 25 关，验证关卡链、可读字段、关键蓝图预览、发布阵容可通关以及低练度阵容无法越过 5-5。
- 战斗领域以 5Hz 固定 tick 运行，自动推进、联盟普通守军/精英、阶段结构、八原型 canonical 技能、星级技能质变、章节机制、核心炮预警/命中、可压制 Boss 核心巨炮、超时和结果只依赖纯 GDScript `BattleSession`；`BattleWorld` 与 `ToiletUnitView` 只投影快照和事件。结算以 `battle_id` business key 幂等写入关卡奖励、蓝图、进度和尝试次数。
- 可压制核心巨炮只在章节 Boss 关启用：`stage_in_chapter == 5` 且处于最终基地阶段时，预警窗口为 `20` ticks / 5Hz 约 `4` 秒，窗口内累计对当前基地结构造成的实际伤害；达到章节目标发 `cannon_suppressed` 并取消炮击，失败保留 `artillery_impact`。五章目标为 `70/85/100/115/130`，仍需人工平衡验证。HUD 与结算显示压制进度、压制次数和命中次数；没有新增操作按钮、货币、奖励、存档字段、任务或成就，自动技能仍默认关闭。
- 3D 表现使用手机 Web 可承受的风格化写实方案：阴沉白天逐章进入黄昏战火、城市大道、远景联盟基地、三段结构破坏、炮弹轨迹、爆炸闪光/冲击波/碎片/烟尘、镜头震动、技能差异化反馈，以及不依赖外部音频素材的程序化原创战斗音效。
- 设置存储已覆盖主音量、低/中/高特效、减少动态与“全局自动技能”；自动技能默认关闭，只有玩家主动开启后才影响战斗。Web 运行时提供焦点与页面可见性状态，战斗失焦后暂停且不自动恢复。
- 营地“下一步行动”由现有进度、尝试次数、生产队列、蓝图、英雄和资源纯派生：新档先侦察，首败后依次引导生产/领取/合成/训练/再战，通关后指向最高已解锁关卡。行动按钮只导航且不改变 revision；结算页失败时只突出一个可执行推荐动作，胜利时预告下一关威胁和蓝图用途。
- 已确认的首版扩展策略：新增战术战报与联盟残骸免费兑换。战术战报只解释战斗结果并导航到可执行成长动作，不发奖励、不写任务进度；联盟残骸本地已实现并由 `run_meta_tests.gd` 覆盖，只来自首次胜利，普通关 `5`、章节 Boss `15`，三项固定兑换为瓷片补给（`8→瓷片40`）、混合零件（`12→零件28+污泥20`）、训练补给（`15→金币120+训练书2`）。这些数值为未真人验证假设，不能宣称已平衡；蓝图补给和生产加速券不属于当前固定项，只能作为延期候选重新评审。
- 任务与战功实现及自动验证已通过：25 个大战役任务对应 25 关首次胜利；3 槽无时限循环小任务由 deterministic generation 从实现 catalog 补位；战功等级 `1–30`，30 级后累计战功继续记录且循环仍可玩，但不产生无限战力。完成与领取分离，领奖走幂等流水、generation、request/business key、claimed 状态和 catalog 奖励对账。普通大战役任务奖励假设为大战功 `60` + 金币 `20`，Boss 为大战功 `160` + 金币 `50` + 训练书 `1`；minor 奖励以实现 catalog 为准。全部数值和真人长期留存仍未验证。
- 成就系统已落地：`GameState.achievements` 顶层五桶为 `progress/completed/claimed/event_keys/counters`；`AchievementCatalog` 固定 24 个永久一次性成就，四类为战役 `6`、工厂 `3`、培育 `7`、收集 `8`。成就完成与手动领取分离，`claim_achievement` 使用 generation `0`、request_id、durable claim ledger 和目录奖励对账；`AchievementService` 使用 command_id 写入 `event_keys` 去重，并只回填可靠证据。奖励白名单仅 `merit/gold/xp_books`，无日周限时、FOMO、广告、IAP、蓝图奖励或战力倍率。
- 当前同人版商业策略仍是免费、无广告、无内购、无概率抽卡。真实商业化属于外部门禁，必须等 IP/素材授权、支付后端、法务、平台政策和隐私合规具备后才可重新评估；未来仅允许讨论纯外观支持者包和赛季外观轨，明确排除 P2W、强制广告、概率抽卡、提前解锁蓝图和本地伪支付。
- 当前 UI 使用 1280×720 设计画布、容器、全屏锚点和横屏安全边距，并嵌入 Noto Sans CJK SC 以避免 Web 中文缺字。出征地图与详情按 45:55 自适应分栏，战斗六名角色技能压为单行，技能和自动开关保留移动触控尺寸；营地提供单一“目标”入口，内部任务/成就分页，成就页为手机横屏单列、分类筛选和触控按钮，使 844×390 下为城市大道 3D 战场与目标管理留出更多纵向空间。本轮最终导出已在 844×390 本地 HTTP 画布完成标题、设置、营地、目标、25 关地图和 3D 战斗检查，控制台无 warning/error；该证据不等于 Chrome Android/Safari iOS 真机通过。
- 动态行动卡会区分“刚解锁且尚未挑战”的推进状态与“最高解锁关已经失败”的卡关状态；后者不再永远重复推荐推进，而会进入生产、领取、合成、训练或再战的纯派生建议，并始终保留当前最高关上下文。
- `project-a/export_presets.cfg` 已提供单线程 Web release preset与 PWA 元数据，`release/` 包含离线页、图标、隐私说明、非官方同人声明、素材许可清单和发布检查表，`release_audit.py` 审计构建文件、hash、体积和 worker 配置。尚未关闭：生产 HTTPS 部署、Android Chrome/Safari iOS 真机、生产源持久化、Builda 受控构建身份、最终素材/IP 授权、完整装备、离线战斗、跨帧率 digest 和 paired 1000。
- `taptap/` 的 UrhoX Lua 2D 版本保留为历史可玩原型；它的实现和远端构建证据不能用于宣称当前 Godot Web 版本已完成。
- 已落地的 `project-a` shell、`game/scripts/{state,commands,domain,persistence,autoloads}/**` 与 `tools/run_meta_tests.gd` 可使用 `CODE:*` 标签；其余规划路径禁止在存在前标记为代码事实。

## 入口或路径

[CODE:project-config](../../../project-a/project.godot)、[CODE:app-shell](../../../project-a/scripts/main.gd)、[CODE:stage-catalog](../../../project-a/game/scripts/domain/content/stage_catalog.gd)、[CODE:battle-session](../../../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:battle-world](../../../project-a/game/scripts/presentation_3d/battle_world.gd)、[CODE:settings-store](../../../project-a/game/scripts/platform/settings_store.gd)、[CODE:web-runtime](../../../project-a/game/scripts/platform/web_runtime.gd)、[CODE:campaign-tests](../../../project-a/tools/run_campaign_tests.gd)、[CODE:release-audit](../../../project-a/tools/release_audit.py)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

当前自动验证覆盖 Godot 4.6.3 headless 导入、Meta、Battle、Lifecycle、UI smoke、Campaign、Platform 与 Presentation suite；同一代码状态的 Web release export、发行审计和 844×390 浏览器检查已通过。任务、战功、成就、Boss 巨炮压制、领取安全、旧档可靠回填和移动横屏 UI 已通过自动与本地浏览器验证；Chrome Android/Safari iOS 真机、生产 HTTPS、跨帧率 digest、paired balance、装备、离线门禁、真人留存与目标系统经济数值仍需外部证据。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

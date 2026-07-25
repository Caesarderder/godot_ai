---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-25
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
  - project-a/tools/run_lifecycle_tests.gd
  - project-a/tools/run_ui_smoke_tests.gd
  - project-a/tools/run_campaign_tests.gd
  - project-a/tools/run_platform_tests.gd
  - project-a/tools/release_audit.py
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - godot --headless --path project-a -s tools/run_lifecycle_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
  - godot --headless --path project-a -s tools/run_campaign_tests.gd
  - godot --headless --path project-a -s tools/run_platform_tests.gd
  - godot --headless --path project-a -s tools/run_presentation_tests.gd
  - godot --headless --path project-a --export-release Web build/web/index.html
  - local-http-844x390-title-settings-camp-campaign-battle
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - runbook.game-verification
---

# 验证矩阵

## 目标

把批准的 milestone 退出条件路由到 Godot Web-first 3D 证据。当前已有 Compatibility shell、v4 Meta、工厂/培育/六人编队、任务/成就目标中心和三阶段战斗自动化基线，但不代表 Web M0、完整长期 GDD、真机或平衡门禁已通过。

## 事实

| Milestone | 证据 |
|---|---|
| 第一幕本地发行候选（PASS） | Godot 4.6.3、GL Compatibility、Meta + Battle + Lifecycle + UI smoke + Campaign + Platform + Presentation tests；`StageCatalog` 精确包含 25 关并具备逐关威胁/反制/反馈/解锁信息；动态行动卡覆盖新档侦察、首败成长、通关推进与最高关卡关恢复，CTA 不改变 revision；1280×720 设计画布下出征页采用 45:55 分栏、六人技能单行和移动触控尺寸；发布阵容全通且低练度阵容不能越过 5-5；同一状态的 Web/PWA 导出、artifact audit 与 844×390 标题/设置/营地/地图/战斗检查通过 |
| M0 Web shell（partial baseline） | Compatibility、单线程 Web preset、PWA 元数据/离线页/图标和 release audit 已配置；生产源音频手势、持久性告警及 Chrome Android + Safari iOS smoke 未完成 |
| M1（partial baseline） | 已验证 command fingerprint/幂等/revision/先存后换、严格 JSON、v1/v2/v3->v4 迁移、主备恢复与 bootstrap gate；internal Web lifecycle、刷新/关闭 crash matrix、20m+5m、600 replay 与离线战斗结算未完成 |
| M2（current baseline） | 已验证固定 seed 新档 8 英雄、指定配方生产永久英雄、L1-L5 clamp/growth、三材料八配方、3 队列、绝对时间离线到期/一次性领取、3 合 1、严格六槽、合成后编队引用迁移和 ID 单调性；真人可读性观察未完成 |
| M3（Act I automated baseline） | 已验证六人三阶段 5Hz 自动攻城、25 关、五个结构 Boss、章节机制、逐关战术提示、八原型技能及星级变化、自动技能偏好、核心炮、Boss 巨炮压制、同输入同结果、超时、result-once、失败后可执行建议和 3D 投影。可压制核心巨炮仅章节 Boss `stage_in_chapter == 5` 最终基地阶段启用；窗口 `20` ticks / 5Hz ≈ `4` 秒；五章目标 `70/85/100/115/130`；窗口内累计当前基地结构实际伤害，达标发 `cannon_suppressed` 并取消炮击，失败保留 `artillery_impact`；HUD/结算显示进度、压制/命中次数；无新增操作按钮、货币、奖励、存档字段、任务或成就，自动技能仍默认关闭。目标数值待人工平衡验证；stable digest、跨 FPS、paired +30pp 和真人平衡未完成 |
| M4（首版经济扩展合同） | 联盟残骸发放与兑换本地已实现并由 `run_meta_tests.gd` 覆盖：首次胜利普通关 `5`、章节 Boss `15`，重复结算不重复发放；三固定兑换项为瓷片补给 `8→瓷片40`、混合零件 `12→零件28+污泥20`、训练补给 `15→金币120+训练书2`，未知/非法兑换拒绝。`run_ui_smoke_tests.gd` 与 844×390 浏览器检查覆盖战术战报标签、首胜残骸反馈、三项回收入口和只导航不改变 revision；真人能否理解战报与经济价值仍未验证。蓝图补给和生产加速券不属于当前固定项，只能作为延期候选；不得提前解锁蓝图、不得概率抽卡、不得强制广告、不得本地伪支付。`5/15` 与三项兑换数值是未真人验证数值假设，真人经济观察未完成。装备、离线战斗收益、完整经济 ledger、pity、facility、1-5 paired +30pp 仍延期 |
| M4.5（任务与战功合同，自动验证通过） | `run_meta_tests.gd` 已覆盖 25 个首胜大战役任务、普通 `战功60+金币20`、Boss `战功160+金币50+训练书1`、3 槽 deterministic generation 补位、完成/领取分离、claimed、generation、request/business key 幂等、批量生产数量、旧档回填、目录奖励对账及篡改拒绝、30 级封顶后战功继续累计；`run_ui_smoke_tests.gd` 和 844×390 浏览器实测覆盖当前 major + 3 minor、主动领取、触控高度、无横向滚动和无每日倒计时。无每日/周常、FOMO、付费轨、广告刷新、蓝图奖励、概率抽卡、强制广告或本地伪支付；所有奖励数值、真人理解与长期留存仍未验证 |
| M4.6（永久成就合同，自动验证通过） | `GameState` 已是 schema v4 / `factory-siege-v4`，顶层 `achievements` 五桶为 `progress/completed/claimed/event_keys/counters`。`AchievementCatalog` 固定 24 个永久一次性成就：战役 6、工厂 3、培育 7、收集 8；奖励白名单仅 `merit/gold/xp_books`。`run_meta_tests.gd` 覆盖成就目录校验、完成/手动领取分离、generation 0、command_id 事件去重、durable claim ledger、目录奖励对账、篡改拒绝、旧档只回填可靠证据和 save/load；`run_ui_smoke_tests.gd` 覆盖单一“目标”入口、任务/成就分页、24 卡单列、四类筛选、领取/进行中/已领取状态、触控尺寸和无横向滚动。无日周限时/FOMO/广告/IAP/蓝图奖励/战力倍率；真人追求感和奖励数值仍未验证 |
| M5 | 全部 headless、Web release export、Chrome Android + Safari iOS 性能/PWA、P01-P05、最终 scope audit；若进入真实商业化，还必须提供 IP/素材授权、支付后端、法务/平台政策审查、隐私合规、退款与回滚证据。当前同人版保持免费、无广告、无内购、无概率抽卡；未来只允许在外部门禁满足后评估纯外观支持者包和赛季外观轨 |
| 当前 docs init | [CMD:docs-lint](../../runbooks/docs-lint.md#docs-lint) 零错误 |

技术自动/设备门槛为 100%；真人观察关键项各 >=4/5，总计 >=45/50。战术战报真人假设是玩家首败后能说出下一步成长动作；联盟残骸真人假设是玩家理解它是免费补进度货币，而非付费钻石或抽卡入口；任务、战功和成就真人假设是玩家理解它是无时限软引导和长期收藏，而非每日压力、广告刷新或付费战令。实现者不能自批，独立 verifier 保存原始输出、设备日志和 manifest hash。

## 入口或路径

[CODE:test-spec](../../../.omx/plans/test-spec-fantasy-idle-expedition.md)。

## 验证

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；自动套件与每次 release export/audit 分开记录，浏览器桌面模拟不能替代 Android Chrome、iOS Safari 或生产 HTTPS 持久化证据。

## 相关节点

[KM:workflow.code-writing-review](../../workflows/code-writing-review.md)。

---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
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
  - project-a/tools/run_presentation_tests.gd
  - project-a/tools/release_audit.py
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
tags:
  - quality:game-verification
  - risk:partial-implementation
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> 当前 Godot 4.6.3 第一幕发行候选拥有七套 headless suite、单线程 PWA 导出配置与产物审计。最终 Web 导出/浏览器证据必须对应同一代码状态；移动浏览器真机、跨帧率 digest 和 paired balance 尚未落地，因此保持 `draft`。

## 目标

在 M0-M5 分阶段验证 Godot Web-first 3D 项目、内容、经济、战斗和手机浏览器。

## 前置条件

本机提供 Godot 4.6.3 可执行文件；M0 落地后还需可写静态站点目录，以及 Chrome Android 和 Safari iOS 真机或等价远程调试环境。

## game-verification

当前可执行 shell smoke 和 v4 headless suite：

```powershell
godot --headless --path project-a --editor --quit
godot --headless --path project-a --quit-after 2
godot --headless --path project-a -s tools/run_meta_tests.gd
godot --headless --path project-a -s tools/run_battle_tests.gd
godot --headless --path project-a -s tools/run_lifecycle_tests.gd
godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
godot --headless --path project-a -s tools/run_campaign_tests.gd
godot --headless --path project-a -s tools/run_platform_tests.gd
godot --headless --path project-a -s tools/run_presentation_tests.gd
godot --headless --path project-a --export-release Web build/web/index.html
Push-Location project-a
python tools/release_audit.py --artifact-dir build/web
Pop-Location

# 本机 GUI Compatibility 视觉证据
godot --path project-a -s res://tools/capture_playable.gd
godot --path project-a --resolution 844x390 -s res://tools/capture_battle.gd

# 尚未落地：后续质量门禁
godot --headless --path project-a -s res://addons/gut/gut_cmdln.gd
godot --headless --path project-a -s res://tools/validate_content.gd
godot --headless --path project-a -s res://tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

`run_meta_tests.gd` 当前覆盖：新档 8 英雄/250 金币/2 经验书/120 瓷/100 零件/80 污泥、固定 seed、L1-L5 培养、严格六槽、资源事务、战斗一次性结算、三材料八配方、三槽生产、绝对时间离线到期/一次性领取、3 合 1 升星、合成后编队引用迁移、自动技能偏好真实写盘/重载/自动施法、英雄 ID 单调、fingerprint 与幂等、business key 冲突、revision、保存失败、严格 JSON schema、v1/v2/v3->v4 迁移、主档/备份恢复，以及启动加载/损坏存档 gate。

`run_battle_tests.gd` 当前覆盖：必须传入 6 人、默认六人队完成三阶段攻城、联盟普通/精英守军、阶段切换、7 个结构目标摧毁与核心电池→装甲→核心硬门控、手动/自动技能、八原型 canonical 技能及各自可观察效果、星级机制质变、核心炮预警/命中、Boss 巨炮压制窗口、高输出触发 `cannon_suppressed`、低输出保留 `artillery_impact`、普通关无压制目标、结构损伤事件、同一快照得到相同结果、超时语义和 `battle_finished` 只产生一次。它尚不替代跨 30/60/120 FPS digest、paired balance 或移动设备性能门禁。

Boss 巨炮压制回归必须继续覆盖：只有章节 Boss，即 `stage_in_chapter == 5`，在最终基地阶段启用可压制核心巨炮；预警窗口 `20` ticks / 5Hz 约 `4` 秒；五章压制目标为 `70/85/100/115/130`，这些目标只代表待人工平衡验证的首轮数值；窗口内只累计对当前基地结构造成的实际伤害；达标发送 `cannon_suppressed` 并取消本次炮击，失败保留 `artillery_impact`；HUD 展示压制进度和剩余时间，结算展示压制次数与炮击命中次数；不得新增战斗按钮、货币、奖励、存档字段、任务或成就，自动技能仍默认关闭。`run_campaign_tests.gd` 覆盖 Boss-only 配置与目标数组，`run_ui_smoke_tests.gd` 覆盖 HUD/结算和无新增按钮，`run_presentation_tests.gd` 覆盖 `cannon_suppressed` 视觉/音频反馈及低特效、减少动态预算。

`run_lifecycle_tests.gd` 当前覆盖：新档 -> 工厂扣材生产 -> 到时领取永久英雄 -> 三个装甲原型合成 2 星并保持六槽有效 -> 使用真实编队构造战斗快照 -> 结算及 receipt exact-once。失败和超时会返回小额、不可替代胜利收益的材料与训练书，避免生产资源归零后形成硬锁。

战术战报与联盟残骸免费兑换的测试合同：战报只根据战斗结果和当前状态给出一个可执行成长动作，打开或导航不得改变 revision；联盟残骸只在首次胜利发放，普通关 `5`、章节 Boss `15`，重复结算不重复发放；当前固定兑换与 `SalvageCatalog` 一致，为瓷片补给 `8→瓷片40`、混合零件 `12→零件28+污泥20`、训练补给 `15→金币120+训练书2`，且不得提前解锁蓝图、触发概率抽卡、依赖广告或接受本地伪支付。蓝图补给和生产加速券不属于当前固定项，只能作为延期候选重新评审。`普通 5 / Boss 15` 与三项兑换数值属于未真人验证假设，测试只能证明规则正确，不能证明经济已平衡。

任务与战功实现及自动验证已通过。回归必须继续覆盖：25 个大战役任务与 25 关首次胜利一一对应；普通大战役奖励为大战功 `60` + 金币 `20`，Boss 为大战功 `160` + 金币 `50` + 训练书 `1`；3 槽无时限循环小任务由 deterministic generation 从实现 catalog 补位；任务完成与领取分离，完成不发奖，领取才走幂等流水；流水包含 generation、request/business key 和 claimed 状态；存档奖励必须与 catalog 对账，篡改时拒绝；重复事件、重复点击、重复命令和存档重载不得复制奖励；战功等级 `1–30`，30 级后累计战功继续但不产生无限等级、战力倍率或卡关必需收益。负向验证必须确认无每日/周常、FOMO、付费轨、广告刷新、蓝图奖励、概率抽卡、强制广告或本地伪支付。以上数值、真人理解与长期留存均未验证。

成就系统回归必须继续覆盖：`GameState` schema v4 / content `factory-siege-v4`；顶层 `achievements` 五桶 `progress/completed/claimed/event_keys/counters`；`AchievementCatalog` 精确 24 个永久一次性成就，分类数量为战役 `6`、工厂 `3`、培育 `7`、收集 `8`；成就完成与手动领取分离，领取只允许 `merit/gold/xp_books`；`claim_achievement` 校验 generation `0`、request_id、目录奖励和 durable claim ledger；`AchievementService.apply_event` 使用 command_id 写入 `event_keys`，重复事件不重复推进；旧档 refresh 只回填可靠证据，包括 cleared stages、Boss、`stage_5_5`、roster 原型/等级/星级、formation 等级、战功、首胜残骸推导值、命令/耐久流水中的生产领取与残骸兑换。负向验证必须确认无日/周/限时、FOMO、广告、IAP、蓝图奖励、联盟残骸直发、抽卡入口或战力倍率。

`run_campaign_tests.gd` 覆盖精确 25 关、关卡链、敌人与结构最小内容、逐关威胁/反制/章节反馈/解锁预览、发布阵容逐关胜利和低练度 5-5 失败；`run_platform_tests.gd` 覆盖设置默认值/往返/坏档回退/归一化和平台焦点信号；`run_ui_smoke_tests.gd` 覆盖 1280×720 设计画布、主 Shell 构造、新档行动卡、单一“目标”入口、任务/成就分页、24 成就单列、分类筛选、领取态、首败后的工厂路线、已通关后新关未尝试/已失败的分流、完成订单优先级、营地及失败结算 CTA 只导航不改变 revision、战术战报标签、首胜残骸反馈、工厂三项回收入口、出征 45:55 分栏、每章五关同屏、六人单行技能区、移动触控尺寸和出征信息展示。

Web export 必须通过 HTTP(S) 静态服务访问，不能以 `file://` 作为证据。设备测试记录浏览器版本、机型、网络、冷启动、FPS、内存、前后台恢复、PWA 更新与存档持久性；所有等待必须限时。

商业化验证门禁：当前同人版必须保持免费、无广告、无内购、无概率抽卡。任何真实商业化都必须先提供 IP/素材授权、支付后端、法务和平台政策审查、隐私合规、退款/回滚方案；在这些外部证据缺失时，不得把纯外观支持者包或赛季外观轨标为可发布功能，更不得实现 P2W、强制广告、概率抽卡、本地伪支付、付费任务轨或广告刷新任务。

## 预期结果

App Shell 预期 headless 导入无错误；七套 suite 分别输出对应 `PASS`，Web release export 生成 HTML/JS/WASM/PCK/PWA 文件且 release audit 通过。844×390 本地 HTTP 浏览器应能完成标题 -> 设置 -> 营地 -> 出征地图 -> 战斗，并确认中文、触控目标、暂停提示、特效和控制台。真机门禁仍要求 Chrome Android 与 Safari iOS 完成一场战斗、前后台恢复、音频和存档持久化。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-27
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/first-30m-contract.md
  - docs/references/constraints/implementation-status.md
  - project-a/project.godot
  - project-a/tools/run_research_onboarding_tests.gd
  - project-a/tools/run_first_30m_journey_tests.gd
  - project-a/tools/run_battle_hud_screen_tests.gd
  - project-a/tools/run_legion_screen_tests.gd
  - project-a/tools/run_factory_screen_tests.gd
  - project-a/tools/run_research_breakthrough_tests.gd
  - project-a/tools/run_goals_screen_tests.gd
  - project-a/tools/run_campaign_objective_projection_tests.gd
validated_by:
  - manual-verification-plan-review-2026-07-26
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_research_onboarding_tests.gd
  - godot --headless --path project-a -s tools/run_first_30m_journey_tests.gd
  - godot --headless --path project-a -s tools/run_battle_hud_screen_tests.gd
  - godot --headless --path project-a -s tools/run_legion_screen_tests.gd
  - godot --headless --path project-a -s tools/run_factory_screen_tests.gd
  - godot --headless --path project-a -s tools/run_campaign_objective_projection_tests.gd
  - godot --headless --path project-a -s tools/run_research_breakthrough_tests.gd
  - godot --headless --path project-a -s tools/run_goals_screen_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - reference.toilet-factory-refactor-plan
  - runbook.game-verification
  - reference.game-state-measurement-framework
---

# 验证矩阵

- 60 关战役：`run_campaign_60_stage_tests.gd` 锁定 60 个唯一 ID、每章 12 关、三关循环、
  3/6/9 精英、12 Boss、单调推荐战力、五章科技墙，以及战术墨镜研发的前置、精确扣费、
  durable ownership 与 exact-once 重放。`run_campaign_tests.gd` 和 `run_battle_tests.gd`
  同时保护原 1-1～1-5 内容、旧章节机制和新增章节终局。

## 证据原则

当前 v6 测试是可复用技术基线，不证明 v3 SLG 合同。新里程碑必须分别记录实现引用、focused
自动证据、浏览器证据和需要真人判断的体验证据。

| 里程碑 | 自动证据 | 交互/设备证据 | 真人证据 |
|---|---|---|---|
| M0 合同与迁移护栏 | 契约 validator、docs lint、v6 golden save | — | 范围复核 |
| M0.5 策划度量基线 | FM/TFA/FL 复算、来源消耗守恒、CP 候选敏感性、关卡需求扫描 | 状态仪表盘可读性 | 能否正确解释卡关与下一行动 |
| M1 永久角色内核 | 升级后属性与 `ΔCP`、三星、技能、派驻、六槽、存档 | debug/query inspection | 理解等级与星级差异 |
| M2 工厂永久成长 | 离线产出、容量、时间回拨、设施升级、成长成本守恒 | 工厂页 844×390 | 工厂产出能形成清晰成长选择 |
| M3 城镇无损纵切 | 胜败撤退、无损结算、reward manifest、exact-once、digest | 3D 战斗、HUD、结算 | 能理解失败成本与下一成长动作 |
| M4 UI/UX | view model、command routing、手动技能、复盘、阵位候选、UI smoke | 四屏、战区直接出击、战术 HUD、结算、编队 844×390 | 无指导完成核心操作 |
| M5 首 30 分钟 | deterministic flow、存档恢复、经济守恒 | 844×390、刷新/关闭、20m session | 复述双向循环并愿意再战 |
| M6 Web 候选 | 全套 headless、export、artifact audit | Android Chrome、iOS Safari、生产 HTTPS | 最终 scope audit |
| M7 长期进度 | v5–v10→v11、周期 generation、批量领奖幂等、十抽 A、60 抽 S、型号专属碎片升星、免费阵营十连保证、S1≥B2、六槽替换、保底持久化 | 三页签、顶层待领取数、30 级奖励轨、招募结果、研发、升星与编队编辑 844×390 | 玩家能否形成阵营认同，并因下一次抽取/升星主动继续 |

## 2026-07-27 当前证据

- M6/M7 生产承接：2026-07-28 Sites 私有生产 v5 已成功发布到
  `https://gray-mirror-faction-game.caesarliu23.chatgpt.site`；仅当前账号可访问。生产 WASM/PCK
  下载哈希与本地可复现候选一致，阵营十连、专属碎片、研发、升星、编队和第二章战斗由
  `run_post_30m_faction_tests.gd` 的 7-seed 旅程覆盖。公开发布与真人继续游玩意愿仍需独立证据。

- M1–M3：`run_balance_tests.gd`、`run_slg_loop_tests.gd`、`run_lifecycle_tests.gd`、
  `run_battle_tests.gd`、`run_campaign_tests.gd` 覆盖升级属性与 `ΔCP`、首章旅程、永久角色、三星、
  派驻、无损结算和 Boss；`run_factory_casualty_tests.gd` 补充无损结算、幂等与旧 schema 迁移兼容。
- 第三章遭遇：`run_battle_tests.gd` 覆盖目标消失/复现、精英真实换位、有限屏幕控制、监军护盾与
  3-5 三模块配置；`run_battle_hud_screen_tests.gd` 和 `run_battle_event_feedback_tests.gd`
  覆盖 HUD/3D 事件边界，`run_progression_cycle_scan.gd` 保持 7-seed 成长路线。844×390
  Compatibility 证据覆盖 3-1 信号消失与 3-4 监军护盾；真人是否能快速重锁目标仍待盲测。
- 第四章遭遇：`run_battle_tests.gd` 覆盖标记索敌、防空锁定/规避、净化临时单位、永久角色免伤、
  4-4 分段教学和 4-5 时间轮换；同一测试以飞行混编、地面混编、寄生混编和永久主队验证没有
  单一硬锁。HUD/3D 边界及战报由对应 focused tests 覆盖，844×390 Compatibility 证据显示
  4-1 标记倒计时和 4-2 地面规避反馈。真人是否愿意主动换阵仍待盲测。
- M0.5：`run_first_chapter_balance_scan.gd` 使用 7 个新档种子扫描真实 `BattleSession`，
  验证同一 Gman 在前三关开局属性一致、前三关稳定胜利、1-4 单人必败及三人基础编队稳定反攻。
  五项战力口径下新档 Gman CP 为 `1603–1683`，前三关推荐线统一为 `1650`；
  1-3 用时为 55.0–58.8 秒，结束生命为 19.3%–35.4%；
  1-5 基础三人 7/7 全败，冲锋升星和装甲升星
  两条命名路线分别 7/7 全胜并落入 70–120 秒自动合同。扫描器会真实执行基础研究、领取和编队，
  不再把“研究开始事件”误当作已授予英雄。`run_first_30m_journey_tests.gd` 另以 14 个干净新档
  （7 seed × 冲锋/装甲二星）串起真实战斗、结算、研究所、十连、编队、资源设施投产与首批
  后勤收取、升星和存档恢复，全程没有直接改状态或注入货币，并使用真实默认
  `auto_skill=false`：普通战斗技能就绪即手动释放，Boss 最终阶段保留到 5 秒预警。两条路线均在
  524–598 秒模型时间内完成且账本非负；冲锋 7/7 至少压制一次巨炮，装甲 7/7 至少守住一次
  炮击。Boss 机制可读性和
  真人接受度仍待验证。
- 内容数据门禁：`run_stage_definition_tests.gd` 校验首章五个 typed `.tres` 的唯一稳定 ID、
  章节坐标、范围、必填威胁/反制文案，以及运行时推荐战力、敌方倍率、单人压力和 Boss 耐久投影；
  随后的 98 场扫描防止数据迁移静默改变首章胜负与时长合同。
- 应用/资产边界：`run_app_bootstrap_tests.gd` 验证显式服务注入、幂等启动和缺失服务失败；
  启动 smoke 与 lifecycle suite 验证真实 Autoload 顺序。`run_asset_3d_tests.gd` 验证八个
  game-owned wrapper scene 均含可渲染网格，`run_presentation_tests.gd` 验证其战斗投影；
  新 Web 包随后通过 artifact audit 与完整 Chrome/PWA smoke。
  `run_font_coverage_tests.gd` 扫描实际运行时脚本、场景、Resource 与项目配置，并通过导入后的
  `FontFile.has_char()` 阻断中文、ASCII 或界面符号漏字；tools、截图证据与零入口 legacy Shell
  不计入玩家字符集。
  `run_ui_focus_tests.gd` 逐一实例化 12 个 authored screen 与 `StageDetailPanel`，递归验证
  `BaseButton / Slider / LineEdit / TextEdit`、动态 CTA、阵位、关卡与战斗技能覆盖层均为
  `FOCUS_ALL`、可取得焦点且具有对应 Godot 控件的高对比可见状态；多控件页面还必须存在向前
  键盘/手柄导航路径。
- M4：`run_ui_smoke_tests.gd` 已迁移到新四入口 App Shell；目标页刷新并呈现新合同里程碑；
  标题、设置、全局自动技能、主动暂停和失焦暂停已接入实际入口；第五章胜利进入独立尾声并可继续
  无尽前线；指挥情报页已展示当前编队 `CombatPower`、能力比、风险、紧缺资源和行动建议；
  战斗页已覆盖自动/手动技能模式、逐英雄技能按钮与阶段 HUD，结算覆盖真实战斗复盘和成长去向，
  军团页覆盖选中阵位后的首屏候选角色；review 回归另覆盖 snapshot 信号复用、减少动态下的
  工厂静态降级，以及战果保存失败的阻断式幂等重试入口；
  横屏壳层回归另覆盖 568×320 短屏、667×375 旧手机、844×390 基准、932×430 现代手机、
  1024×768 平板、1280×540 超宽和 390×844 方向门禁；自动断言 CSS 安全区探针、48 CSS 像素
  触控换算、旋转期间战斗安全暂停和页面恢复。设置页覆盖双栏独立滚动，工厂覆盖新档空地、
  可负担建造 CTA、原子落成和存档往返；
  战斗暂停回归覆盖全屏输入拦截、同一战斗会话冻结、继续、撤退、音量、减少动态、失焦保持暂停
  和语义返回键识别。
  `run_battle_hud_screen_tests.gd` 另对独立 `BattleHudScreen` 验证阶段/战线/炮击倒计时投影、
  编队对应的冲锋打断/装甲承炮提示、自动/手动技能状态、满能量 CTA、阵亡解释，以及 1-1
  首次技能的整卡点击提示与成功确认；Compatibility 844×390 截图和 Web Chrome smoke 均已
  覆盖集成后的真实战斗画面。`ui-first-skill-tutorial-844x390.png` 另记录提示位置、触控目标、
  中文技能名和战场留白；`ui-first-skill-result-844x390.png` 记录 accepted 事件驱动的实际伤害
  确认。结果截图现由真实技能卡 `pressed` 信号经 App Shell、`BattleWorld.request_skill()` 和
  一个 5Hz tick 产生；工具监听并断言动态角色 ID、`skill_used`、正数 `effective_damage`、
  施法后能量与世界 VFX，不再直接调用 HUD 或手工写两条 96 伤害。当前新档权威结果为
  “Gman 指挥官 · 统帅碾压：造成 54 伤害”。两者都不替代目标玩家首次理解盲测。
  1-1 通过 StageCatalog 显式提供一次 `30000bp` 首次反攻强化，HUD 在点击前公开该事实；后续
  施法和其他关卡保持 `20000bp`。98 场首章扫描测得 1-1 为 44.6–58.8 秒，并继续满足单人
  1-4 0/7、援军 1-4 7/7、未成长 1-5 0/7、冲锋/装甲二星 1-5 各 7/7；14 条手动技能新档
  旅程继续通过，因此首局爽点没有穿透中坎与 Boss 大坎。
  `run_presentation_tests.gd` 进一步验证 accepted 装甲格挡事件在中画质产生文字、防御环、核心
  闪击、受控镜头震动与独立音效，在低画质/减少动态下保留文字和形状但移除次级闪击与震动；
  `ui-battle-guard-counter-844x390.png` 证明关键反馈位于基地轮廓上方且不遮挡技能卡。
  `run_legion_screen_tests.gd` 对独立 `LegionScreen` 验证下一关战力差、候选职责、换人后的军团
  战力变化和语义部署请求；新 844×390 军团截图显示首屏即可比较阵位，而旧动态军团树移除后
  UI smoke 与 Compatibility capture 均不再产生退出资源泄漏。
  `run_first_formation_flow_tests.gd` 进一步使用真实 App Shell 与命令执行器，验证十连后默认
  空前排、装甲/冲锋依次推荐、两次上阵持久化、下一空位推进和精确 1-4 反攻 CTA；
  `ui-first-formation-844x390.png` 证明首次候选与职责说明在基准横屏首屏内可见。
  `run_factory_screen_tests.gd` 对独立 `FactoryScreen` 验证固定库存、互斥 HUD、研究所资格解释、
  三步网格建造和“确认后才扣资源”的交易边界；新 844×390 截图证明库存文案不换行挤压，
  右侧建造决策与左侧 3D 选址同时可见。
  `run_legion_screen_tests.gd` 进一步锁定升级、升星、技能研究的当前/需要/操作后和独立资源
  缺口；四项核心余额由 App Shell 常驻在管理页面右上角，军团成员列表与研究蓝图不再重复占用
  内容区。`ui-global-resource-hud-844x390.png` 证明金币、军团数据、工业材料和招募券
  在标题右侧、菜单左侧完整可读；`run_blueprint_screen_tests.gd` 锁定基础蓝图需要 0、
  余额不变和调试阶段仅耗时 5 秒，并在模拟 App Shell 的 `844×342` 内容区检查十连、基础研发、返回按钮
  的全局边界与焦点可达性；`run_new_player_welfare_tests.gd` 与 `run_balance_tests.gd` 锁定
  `star_upgrade_quote` 和普通/免材料执行结果同源。上述测试不替代 844×390 真实浏览器视觉验收。
  研究所回归覆盖 1-4 首败后的主动建造入口、带主干连线的四分支八节点科技蓝图、两个基础节点 CTA 和返回基地路径。
- 首败研究纵切：`run_research_onboarding_tests.gd` 覆盖早期失败不解锁、1-4 首败开放基础信号和建造资格、
  信号十连只入库冲锋/装甲图纸，玩家主动放置研究所并逐张研发后才授予稳定 ID 永久角色、重复解锁拒绝、
  三人六槽上阵以及后续失败不重复触发。
  `run_research_breakthrough_tests.gd` 进一步覆盖信号页一次性免费十连：正好十张设计卡、
  不直接创建角色/材料/芯片、长期 A 保底不变、二次领取拒绝、receipt 回放、save roundtrip，
  以及两张图纸研发后分别获得 B/A 永久角色。目标页 UI
  smoke 覆盖“大目标—中目标—小目标—当前坎—过坎办法—唯一 CTA”。
  `run_goals_screen_tests.gd` 独立实例化 authored `GoalsScreen`，覆盖三层目标、大小卡点、恢复
  文案、精确关卡 CTA、三页签语义信号、30 级战令轨和指挥官长期进度。
  `run_battle_result_screen_tests.gd` 验证 1-4 反攻后“选择工业支援”成为唯一高优先 CTA，
  不再让“进攻下一城镇”绕过资源设施、收取后勤与自主升星；`ui-action-auto-settlement-844x390.png`
  提供 844×390 Compatibility 视觉证据。
  `run_battle_hud_screen_tests.gd` 验证反攻开场的装甲承伤/冲锋压制提示；
  `run_first_formation_flow_tests.gd` 与 `run_battle_result_screen_tests.gd` 验证结算从真实出战、
  逐角色伤害和承伤统计生成过坎证据；`ui-counterattack-proof-844x390.png` 证明 844×390 下
  因果复盘与下一行动同时可读。
  `run_first_growth_flow_tests.gd` 覆盖反攻结算后先并列两条 Boss 成长路线、真实 CP/成本预览、
  两按钮可选，再进入独立资源设施选择、建成后定位投产收取；`ui-first-industrial-choice-844x390.png` 与
  `ui-first-growth-choice-844x390.png` 证明三个设施和两条成长路线分别在基准横屏首屏可操作。
  同一聚焦测试继续覆盖升星后所选路线、统一战力对比、5 秒技能时机和精确 1-5 战斗入口，并
  分别验证“成长未完成”“巨炮机制/技能时机”“阵容/战力”三类失败恢复；
  `ui-boss-ready-844x390.png` 与 `ui-boss-timing-recovery-844x390.png` 证明验证态和时机失败
  结算在 844×390 首屏只保留匹配的主要行动。
  `run_chapter_one_completion_tests.gd` 验证首章专属标题、冲锋压制与装甲格挡两种真实路线证明、
  七行动闭环、按当前状态生成的第 2 章/招募/战令解锁摘要，以及主 CTA 先进入真实免费阵营十连，
  不跳过角色池选择直接续战；双尺寸 `ui-chapter-one-complete-*` 与
  `ui-chapter-one-faction-recruit-*` 证明奖励、贡献、路线兑现、实际解锁和招募交接共同可读。
  `run_campaign_tests.gd` 与 `run_ui_smoke_tests.gd` 共同锁定首墙侦察口径：1-4 玩家可见
  反制只指向信号图纸、研究所研发、永久装甲/冲锋援军和反攻，不再泄漏研究所抽卡、九兵量产或三合一；
  1-5 推荐只保留两条已验证二星路线，首章巨炮预警合同为 5 秒；
  `ui-first-wall-reconnaissance-844x390.png` 提供真实战区首屏证据。
  `run_balance_tests.gd` 与 UI smoke 进一步验证情境行动优先级：1-4 零尝试时即使能力比极低，
  也只显示 48px“试探炮台防线”且隐藏通用培养按钮；记录一次尝试后才恢复成长建议。
  同一领域测试覆盖首败后“信号图纸 → 建研究所 → 两次研发 → 编队 → 反攻”的持久状态矩阵；UI smoke
  验证战区“建造研究所”语义行动准确打开研究设施而非通用军团页，
  `ui-first-wall-recovery-844x390.png` 保存首败恢复首屏。
  `run_chapter_one_completion_tests.gd` 继续覆盖章节间承接：首章结算先进入阵营起手十连；领取后
  目标中心、标题与基地任务都从 durable receipt 恢复同一个抽取核心的研发目标，不退回泛化的
  “先培养军团”，对应 CTA 直接进入该型号所在科技分支。
  `run_post_30m_ui_journey_tests.gd` 再以真实主场景按钮串联十连结果、定向科技节点、研发领取、
  第三个空编队槽、三场实战证明、精确 `hero_id` 升星与 2-5 目标；它与
  `run_campaign_objective_projection_tests.gd` 共同防止刷新或跨屏后阵营身份和下一行动分叉。
  `capture_post_30m_faction_journey.gd` 生成十连结果、金框科技核心、自动聚焦编队候选、升星待命
  、质变解锁与第二章质变结算六张 844×390 连续证据；两秒扫视无需滚动即可辨认当前阵营核心、
  唯一主操作，以及 2★专属机制对突破 2-5 的实际贡献次数。`run_post_30m_faction_tests.gd`
  同时锁定真实第二章战斗会为抽取核心产生对应机制计数，避免渲染 fixture 代替领域事实。
  同一 capture 继续生成 `ui-chapter-three-reorientation-844x390.png`：2-5 结算 CTA 打开第三章
  3-1 侦察页，显示电视控制威胁、75% 极高风险与“先培养军团 / 仍要试探”选择。
  `run_post_30m_ui_journey_tests.gd` 锁定 CTA 完整位于 844×390 视口且章号由目标关卡推导。
  `run_battle_tests.gd` 锁定 2-1 与 2-5 的共振强度端点、2 秒预警和真实扣能量；
  `run_battle_event_feedback_tests.gd` 锁定章节事件穿过 3D 表现边界，
  `run_battle_hud_screen_tests.gd` 锁定手动/自动提示与实际损失文案。
  `ui-chapter-two-resonance-warning-844x390.png` 和
  `ui-chapter-two-resonance-impact-844x390.png` 提供真实 BattleWorld 小屏渲染证据。
  `run_campaign_objective_projection_tests.gd` 在不经过 UI 的情况下锁定同一事实 owner：
  首章进行中保留当前小目标；首章完成但低于 2-1 挑战线时，标题/基地/目标中心共享精确战力缺口
  与“先培养军团”；达到挑战线后，三者共同切换为侦察 2-1。该测试防止 App Shell 的跨页面
  文案和路由重新分叉。
  网格建造回归覆盖用途卡、费用可读性、三步引导、空格选择、确认前不扣款、坐标持久化以及
  `ui-construction-placement-844x390.png` 放置态证据。
  帮助中心回归覆盖标题/设置双入口、双栏滚动、建造与技能说明、隐私与运行版本、48 像素返回
  操作，以及 `ui-help-844x390.png` 真实渲染证据。
  标题入口回归覆盖新档、进行中和五章完成三种主 CTA，并校验城镇、英雄、指挥等级、下一目标
  均来自当前持久状态；`ui-title-844x390.png` 提供旧档渲染证据。
  `capture_ui_review.gd` 已在本机 Compatibility 图形运行生成标题、设置、基地、指挥情报、战区、
  军团、目标、终章、战斗与结算的 844×390 截图。
- M6 本地部分：Web release export 与 `release_audit.py --artifact-dir build/web` 通过；
  原创 PWA/application 徽记通过 safe SVG 校验，并由同一 Web preset 导出 144/180/512 与
  Apple touch PNG；32 像素缩略检查仍能辨认瓷甲盾、工厂核心与突破箭头。
  clean revision `92426358ffa2` 的确定性回滚归档包含 16 个候选文件，连续两次打包 SHA256
  均为 `4f43f9418145bb7417212ac73fcd7ed9f139e655ef30b707101f70ec38b59ec8`；隔离恢复、逐文件
  SHA256 与恢复目录发布审计通过。生产监控阈值、具名事故负责人、托管/CDN 切换与生产源演练
  仍未完成。
  `run_web_browser_smoke.mjs` 通过本机 HTTP 和真实 Chrome 验证 844×390 WebGL2 Canvas、390×844
  原生竖屏提示、1280×540 超宽横屏、旋转恢复和触控进入基地，
  PWA Service Worker 接管、在线刷新与关闭服务器后的离线重启；运行阶段无控制台/意外网络错误，
  `/userfs/.../save_v1.json` 在在线刷新及离线重启前后身份保持；设置页可下载合法 v8 JSON，再经
  浏览器文件选择器导回、预览、二次确认恢复，并将旧主档保留为 `.bak`。
  `run_web_first_battle_smoke.mjs` 另用隔离新 profile 从标题经基地真实进入 1-1，通过真实结算
  CTA 连续推进到 1-4 首败；当前 Chrome 150 于 844×390 在 181.5 秒完成，IndexedDB 主档精确
  记录 1-1/1-2/1-3 通关、1-4 一次尝试且未通关、onboarding 进入研究突破，全程 0 运行时异常、
  0 非预期 console error、0 网络失败。首战与 `browser-first-wall-defeat-844x390.png` 保留
  战斗目标、逐关成长和“返回基地建造研究所”证据；重复触控本身不冒充真人主动技能理解证据，
  同一旅程随后在真实 844×390 网格放置研究所、等待并原页验收当时版本的 75 秒施工，完成 claim-once
  免费十连并把装甲/冲锋两个具体永久 hero ID 写入 `troop_1/2`；候选 `0b3cc8542623` 用时
  356.3 秒继续点击真实反攻 CTA、轮询三张英雄技能卡并取得第二次 1-4 尝试胜利。存档的
  `cleared_stages` 精确新增 1-4，且运行期仍为 0 异常、0 非预期 console error、0 网络失败。
  `browser-research-placement-ready-844x390.png`、
  `browser-research-ready-to-claim-844x390.png`、`browser-research-breakthrough-result-844x390.png`
  和 `browser-first-formation-complete-844x390.png` 保存恢复链转折；
  `browser-first-wall-counterattack-started-844x390.png` 与
  `browser-first-wall-counterattack-victory-844x390.png` 证明援军开场提示、胜利、单人失败到
  三人反攻的因果复盘，以及唯一“选择工业支援”出口。候选 `19279cf6bf84` 随后在同一新档
  选择陶瓷厂、放置到 `[-1, 2]`、等待当时版本的 30 秒施工、验收并领取预置的 6 陶瓷，再比较两条
  `7/7` 路线并把冲锋永久升至 2★；完整旅程用时 395.3 秒，仍为 0 异常、0 非预期 console
  error、0 网络失败。七张 `browser-first-industrial-*` / `browser-first-growth-*` 证据覆盖
  设施选择、网格交易边界、施工、首批收取、二选一和 Boss 验证入口。收取后零库存按钮现禁用
  并显示“暂无可收取”，不再广告必然失败的假行动。候选 `ec1ff8558a67` 又把相同隔离新档
  连续推进到 1-5：Chrome 150 / 844×390 在 474.3 秒内完成 Boss 一次胜利并解锁 2-1，
  `cleared_stages` 精确包含 1-1 至 1-5，2-1 尝试数保持 0，710 次技能卡触控期间为 0
  runtime exception、0 非预期 console error、0 failed request。章节结算记录冲锋角色
  3389 伤害、75% 占比与压炮 4 次，并将唯一主行动交给第二章侦察；侦察页呈现
  6476/15500、42% 极高风险和培养/试探选择而不自动开战。该数值属于锯齿曲线改造前的历史
  浏览器证据；当前 2-1 推荐线为 6900，尚未重新执行这段视觉旅程。
  `browser-first-boss-started-844x390.png`、`browser-first-boss-cannon-window-844x390.png`、
  `browser-chapter-one-complete-844x390.png` 与
  `browser-chapter-two-reconnaissance-844x390.png` 保存真实 Web 状态。中段截图只能证明
  战斗内技能反馈；炮击预警的五秒可理解性仍必须由真人盲测回答，不能由高频自动触控替代。
  候选构建现对 HTML/JS/WASM/PCK 记录确定性 gzip-9 体积并执行 30 MiB 硬门禁；排除零引用的
  legacy `scripts/main.gd` 并加入正式品牌启动图后，revision `127323a` 的当前 PCK 为
  `18.92 MiB`，gzip-9 初始 payload 为 `27.62 MiB`，仍低于 30 MiB 硬门槛，但比 20 MiB
  目标高 `7.62 MiB`。新增两条 OGG 音乐约占 3.88 MiB 原始体积；16.06 MiB 的完整 Noto CJK
  源字体是下一项主因，不能用系统字体替代 Web 中文覆盖。运行字符清单当前为 981 个，
  `run_font_coverage_tests.gd` 必须在任何裁剪后重新证明全部覆盖。
- M8 本地试玩证据工具：`run_platform_tests.gd` 覆盖显式 opt-in、事件白名单/去重、256 条上限、
  版本/样本量/时间窗、续接、导出和关闭删除；同一报告从白名单事件派生 12 个首章里程碑、相邻
  节点耗时、下一缺失节点、首个有效输入、关卡尝试、失败命令、纯导航连跳和排除战斗区间后的
  最长停滞。越序升星不会绕过研究所、编队与后勤节点，并明确这些指标不能证明理解或乐趣。
  Chrome smoke 覆盖报告下载、隐私字段检查、在线/离线续接与 IndexedDB opt-out 删除。真实
  20–30 分钟样本与玩家访谈仍未发生。
- 首章战斗心流诊断：`run_platform_tests.gd` 锁定技能成功/过早点击、分关手动输入和最长手动
  战斗决策间隔，不携带英雄 ID；暂停及自动技能区间不会产生假 90 秒停滞。Settings/UI/Lifecycle
  回归锁定玩家可见状态与 App Shell 记录路径；这些指标只为 5 人盲测定位录像，不替代中立访谈。
- 军团数据技能消耗：`run_slg_loop_tests.gd` 锁定技能 II/III 的同源 quote、原子消费和研究所门禁；
  14 条 `run_first_30m_journey_tests.gd` 新档证明冲锋/装甲路线在 Boss 后都立即负担得起技能 II。
  `run_chapter_one_completion_tests.gd` 锁定第二章成长直达成员页、精确 `80 金币 + 4 军团数据` 成本与
  可操作按钮；`ui-chapter-two-skill-growth-844x390.png` 提供基准横屏首屏证据。revision
  `ea51420b56cb` 的真实 Chrome 150 新档又在 474.1 秒内从 2-1 侦察进入成员培养，点击正式
  Gman 技能按钮，证明 Lv.2 与六项精确成本持久化，再通过底部战区导航返回 2-1，尝试数保持
  0；698 次战斗技能触控期间三类运行错误均为 0。新增三张
  `browser-chapter-two-skill-growth-*` 截图覆盖交易前、交易后和回访侦察。
- 当前替代证据：clean candidate `5f5b5e5721cb` / `0.13.53-faction-ten-handoff.1` 已由
  Chrome 150 在 844×390 隔离新档连续跑通完整首章与阵营交接。真实链路包含开局只够研究所的
  工业材料、关卡图纸研发、1-4 单人首败与三人反攻、首屏二星二选一、显式领取新游补给礼包、
  5 秒陶瓷厂施工/验收/收取、1-5 Boss、免费阵营十连、两名同评级核心比较、durable 音波核心
  选择及其科技图纸聚焦。IndexedDB 证明 2-1 尝试仍为 0；425.6 秒、790 次技能触控期间三类
  runtime/console/network 错误均为 0。`browser-first-industrial-gift-claimed-844x390.png`、
  `browser-chapter-one-faction-recruit-844x390.png`、`browser-faction-recruit-result-844x390.png`
  与 `browser-faction-blueprint-focus-844x390.png` 是本轮新转折证据。此项取代旧的“首章后直接
  升级 Gman 技能”浏览器路径；阵营核心研发、入队、三场证明和专属碎片升星仍缺同一新档的
  连续 Web 证据。
- 首章后成长周期：`run_progression_cycle_scan.gd` 从 7 个固定 seed 的保守 1-5 后账本出发，
  先领取新游福利、开启 18/10/8 后勤箱并使用一次免材料升星核心，再用明确贪心策略消费永久
  成长资源并运行真实 `BattleSession`。首轮编队 CP `9172–9554`，2-1 至 2-4 全胜、2-5
  全败且均到达最终阶段、摧毁 6 个结构并把核心压到 50.80%–81.69%；第二轮 CP
  `10961–11558`，2-5 至 3-4 全胜、3-5 全败。`run_battle_tests.gd` 另锁定未配置关卡继续使用
  46 伤害/42 tick 默认巨炮，并锁定经过任意 tick 后都不会因旧核心过载参数强制判负。
  `run_balance_tests.gd` 另锁定主动技能研究会进入角色与战斗快照的同源战力。该自动证据证明
  确定性节奏合同，不证明真人会感到卡点合理或资源消费选择有趣。
- 新游福利：`run_new_player_welfare_tests.gd` 锁定 1-5 前不可领取、固定 durable ledger 抵抗
  换 command/business id 重复领取、后勤箱 exact-once、核心仅供 1★→2★、仍扣 4 份英雄数据/
  碎片、工业材料零扣除、strict codec 往返与保存失败不发布候选状态；`run_goals_screen_tests.gd`
  和 `run_legion_screen_tests.gd` 锁定福利三态、开箱请求及英雄卡核心按钮。该证据不证明福利
  文案与反馈能产生“开挂感”或提高继续游玩意愿。
- Web 私密存储证据：`run_web_private_storage_smoke.mjs` 通过 CDP 原生隔离上下文证明同一 Chrome
  私密会话刷新后存档 hash 不变，销毁上下文再新建时得到不同存档；设置页截图同时证明玩家看到
  “未确认持久存储”与下载备份指引。
- Web 阻断存储证据：设置 `GODOT_WEB_SMOKE_BLOCK_INDEXEDDB=1` 后，同一工具会在任何页面脚本前
  注入 `SecurityError`，断言候选仍启动为 844×390 可见 Canvas，并记录浏览器与候选 revision；
  `run_platform_tests.gd` 锁定 `blocked` 能力状态，`run_title_screen_tests.gd` 锁定首屏明确写出
  “刷新后会丢失”，浏览器截图复核主 CTA 未被风险提示挤出。最终生产源持久化仍是独立门禁。
- M7 领域与 UI：`run_meta_progression_tests.gd`、`run_meta_tests.gd`、`run_ui_smoke_tests.gd`
  覆盖 v8 往返、v5/v6/v7 迁移、任务与批量等级/战令/成就领奖、30 项成就、十抽 A、60 抽 S、
  专属数据升星、招募英雄六槽替换和顶层待领取计数；
  `ui-pass-844x390.png`、`ui-achievements-844x390.png`、`ui-faction-recruit-result-844x390.png`、
  `ui-formation-edit-844x390.png` 提供本机渲染证据。
- 可访问性本地基线：`run_ui_focus_tests.gd` 验证作者场景和动态按钮均可聚焦且有高对比焦点样式；
  `run_font_coverage_tests.gd` 扫描运行时中文字符覆盖；`run_presentation_tests.gd` 验证“减少动态”
  会即时清除镜头震动，并关闭单位呼吸摆动、受击缩放和技能前冲，同时保留血条、状态颜色、
  炮击文字倒计时、技能结果和胜负结算等静音可读反馈。设置页两个 `HSlider` 使用 Godot 4.6
  `grabber_area_highlight` 提供真实焦点轨道，`ui-settings-slider-focus-844x390.png` 的
  Compatibility 截图证明聚焦主音量为金色白边、未聚焦音乐音量保持青色。屏幕阅读器语义仍须在
  真实浏览器/设备验证，自动测试不能替代该项。
- Web 键盘集成：`run_web_browser_smoke.mjs` 在七档视口与方向恢复后通过 CDP
  `Input.dispatchKeyEvent` 向 Godot Canvas 发送 `Enter`，激活 `TitleScreen` 已聚焦的主 CTA；
  后续设置、试玩报告、备份导入、刷新和离线 PWA 继续使用触控并全部通过。工具在 Chrome
  `SIGTERM` 超时后强制 `SIGKILL` 并等待退出，避免 PASS 后 CI 被残留子进程挂住。
- 音乐表现基线：`run_music_director_tests.gd` 锁定标题静音、基地/战斗/Boss 状态、任意连续或
  中断淡化后只有一个 Stream voice、后台暂停/恢复和清理；Platform/Settings 测试覆盖默认值、
  旧配置回退、持久化、归一化与语义 UI 事件，UI smoke 锁定 App Shell 的标题、基地和普通战斗
  路由。真实 Web 首次手势、循环接缝和移动端 Stream 仍是浏览器/设备门禁。
- 首战目标反馈：`run_battle_hud_screen_tests.gd` 验证 HUD 从当前阶段第一个存活结构投影
  “突破/摧毁 + 名称 + 耐久”，并在路障死亡后切换到城市；表现、UI 与 battle 回归证明它没有
  改变领域结果。`ui-first-skill-tutorial-844x390.png` 使用真实 1-1 单阶段配置证明目标前缀与
  技能教学、三个战斗操作按钮在基准横屏内共存。
- 战斗反馈所有权：App Shell 不再为接受或拒绝的技能请求显示全局顶层 toast；接受后的实际
  结果与未就绪说明均由 `BattleHudScreen` 状态行承载，炮击警告对两者保持优先级。
  `run_battle_hud_screen_tests.gd` 覆盖警告期间拒绝反馈不抢占、警告消失后再显示；
  更新后的 `ui-first-skill-result-844x390.png` 证明实际伤害、阶段目标和战场同时可读。
  revision `23be7a332c88` 的 Chrome 150 完整新档旅程再以 471.2 秒、702 次技能触控和三项
  runtime/console/network 零失败验证导出候选；Boss 中段真实截图不再出现全局技能 toast。
- 压炮确认窗：`run_battle_tests.gd` 锁定达到阈值当 tick 即成功、accepted warning 以
  `suppressed=true` 保留 3 tick、期间无 impact/重复计数并在精确时刻移除；HUD 测试锁定绿色
  “巨炮已压制 · 安全窗口”。`capture_cannon_suppressed.gd` 从真实 `BattleSession` 事件与
  snapshot 驱动正式 HUD，生成 `ui-boss-cannon-suppressed-844x390.png`。revision
  `87ade1230422` 的 Chrome 150 全章回归用时 473.4 秒，710 次技能触控，runtime exception、
  非预期 console error、failed request 均为 0；固定时点 Web 截图未命中 0.6 秒窗口，不声称
  它替代确定性截图或真人理解验证。
- 结构突破反馈：`run_battle_tests.gd` 锁定摧毁事件的 ID/名称/lane/kind，
  `run_presentation_tests.gd` 锁定普通画质的世界文字+冲击环以及低画质/减少动态的纯文字预算；
  `ui-first-breakthrough-844x390.png` 证明首战“防线突破”与 HUD 下一城市目标同时可读。
- 首战世界构图：`BattleWorld` 从同一只读 battle snapshot 投影当前阶段第一个存活敌人或结构，
  以友军前线和目标共同构图，并用可复用金色双环与方向箭头标记目标；远目标预览受限，镜头不会
  越过军团。`run_presentation_tests.gd` 覆盖敌人优先级、结构回退、远距截断和单一 marker。
  `capture_first_skill_tutorial.gd` 不再伪造 HUD 前线而保留出生点世界，而是推进真实 1-1 直到
  首次技能充满后，用同一 snapshot 生成 844×390 教学与实际结果证据；真人两秒识别仍待盲测。
- 首战世界视觉层级：背景道路/建筑使用低饱和冷灰；敌方结构拥有面向进攻方的橙红立面条和结构
  灯；零号永久角色独占青色指挥环与方向楔形，当前目标继续使用更大的金色环和箭头。
  `run_presentation_tests.gd` 验证结构标记与队长标记节点，Compatibility 截图验证两种地面环方向
  正确且角色位于真实推进位置。截图工具在每个领域 tick 同步步进 `ToiletUnitView`，不再把已推进
  的 snapshot 与仍停在出生点的表现模型拼成伪证据；50% 缩图识别仍待目标玩家盲测。
- 目标卡点内容边界：`ObjectiveHurdleDefinition` 与七个首章 `.tres` 分离稳定 task ID、大小坎、
  失败原因和过坎办法；固定 preload Catalog 校验唯一性与完整性，并向
  `CampaignObjectiveProjection` 返回 detached view。`run_objective_hurdle_definition_tests.gd`
  覆盖七段引导一一对应、1-4 大坎与免费十连恢复、未知 ID fail-closed 和共享 Resource 不可被
  view 调用方篡改；投影、研究引导、UI smoke 与 14 条新档旅程回归通过。
- 行动任务内容边界：七个 `OnboardingTaskDefinition` 引用十二个
  `OnboardingObjectiveDefinition`，固定 Catalog 校验稳定顺序、唯一 ID、自然行为条件、CTA 和
  完整奖励预算；`run_onboarding_definition_tests.gd` 锁定 1-4 首败到免费十连的大坎恢复、
  工业建造—收取—二星成长三个小目标、未知 ID fail-closed 与嵌套 detached view。研究引导、
  SLG、Meta、UI、启动和 14 条首 30 分钟新档旅程回归通过。
- 基础图纸十连内容边界：`ResearchBreakthroughCardDefinition` 与十个 `.tres` 锁定冲锋/装甲
  B/A 设计与八张同型重复设计数据；Catalog 校验顺序、评级、字段和不泄漏其他图纸。
  `run_research_breakthrough_tests.gd` 验证首败门禁、十卡、零角色/材料 delta、pity 隔离、
  重复业务拒绝、receipt replay、存档往返及两次研发；`run_first_formation_flow_tests.gd` 验证
  装甲/冲锋两次真实上阵和
  完成后直达 1-4 反攻。14 条新档旅程证明两条后续二星路线经济结果未漂移。
- 仍缺：Firefox 桌面、Android Chrome、iOS Safari、生产 HTTPS、真人首 20–30 分钟及最终 IP/商店审查。

## 必测不变量

- 永久角色不会删除；
- 实时 HP 不写回永久角色状态；
- 战斗结算 exact-once；
- 工厂最低产能和下一永久成长可达；
- 同资源不形成稳定自我增殖；
- 旧战备字段读取后归一为 100；
- v6 迁移失败可回滚；
- UI 不直接改持久状态；
- 无自动推图、量产单位或 P0 图纸抽取入口。
- UI、成长预览和关卡能力比只使用 `CombatPower`；不得使用账号总战力或页面私有公式；
- 角色等级升级必须同时增加基础属性与 `CombatPower`；
- 预制阵容通关不得替代从新档开始的经济可达性扫描；
- 金币不得显示为工厂直接生产；资源换算不得把独立门禁压成一个固定全局汇率；
- 新乘区、货币或商品必须通过通胀、死锁、内容寿命和非付费可达性审查。

## 现有可复用基线

- `run_battle_tests.gd`：确定性 tick、三段攻城与结果结构；
- `run_lifecycle_tests.gd`：命令、存档与重放；
- `run_campaign_tests.gd`：60 关内容骨架与原五关机制兼容；
- `run_platform_tests.gd`：Web 生命周期；
- `run_presentation_tests.gd`：3D 事件投影；
- release export 与 artifact audit。

`run_factory_casualty_tests.gd` 已停止执行永久伤亡旧断言，现可作为无损结算和迁移兼容的补充证据；
它不覆盖首 30 分钟生产闭环或真人体验。

## 验证

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；
自动测试、浏览器设备和真人试玩必须分别记录，不能互相替代。

---
contract_version: 7
project_id: toilet-factory-siege
last_updated: 2026-07-27
km_id: reference.game-contract
km_type: reference
domain: product
status: active
owner: maintainers
last_verified: 2026-07-27
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/product-design/game-state-measurement-framework.md
  - docs/references/constraints/product-boundaries.md
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - node .codex/skills/godot-producer/references/practices/game-project-contract/scripts/validate-contract.mjs .
tags:
  - reference:project-contract
  - workflow:impact-analysis
related:
  - reference.skibidi-toilet-idle-siege-gdd
  - reference.toilet-factory-technical-design
---

# 马桶人工厂攻城项目契约

本文件是制作人、策划、程序、美术、音频和测试共享的项目级状态源。详细规则由
[主 GDD](references/product-design/skibidi-toilet-idle-siege-gdd.md) 维护；当前代码事实由
[实现状态](references/constraints/implementation-status.md) 维护。

## GC-001: 玩家承诺与核心循环
- owner: producer
- status: accepted
- accepted_intent: 玩家从唯一永久英雄 Gman 开始，通过主动攻城暴露职责缺口，再把战果转化为研究所、确定性永久援军、编队调整和自主成长，逐步把地下工厂经营成支撑永久军团的战争机器。
- acceptance_criteria: 首局连续完成 Gman 单人前三关、1-4 首败、研究所建造、免费研究突破十连、冲锋与装甲永久入列、三人编队和 1-4 反攻，再自主选择一条成长路线攻克 1-5；角色不得永久删除，关键路径不得因资源、失败或抽卡死锁。
- implementation_reference: project-a/scripts/slg_main.gd, project-a/game/scripts/commands/command_executor.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd
- conflict_references: docs/game-contract.md@contract_version-1, project-a/game/scripts/state/game_state.gd
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-006
- handoff_from: producer
- handoff_to: programming
- handoff_request: 以永久角色、工厂后勤资源、设施三态、六槽编队和主动攻城为运行时权威；不得恢复量产兵或图纸抽取旧循环
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 运行时与首章合同已切换到永久援军路线；量产兵、图纸抽取和三前排旧方向已明确取消，
  不再作为缺失功能。浏览器存档已支持状态提示、JSON 下载、严格校验、进度预览和二次确认恢复。
- last_updated: 2026-07-27
- last_verified: —

## GC-002: 永久角色、等级与星级
- owner: game-design
- status: accepted
- accepted_intent: 每名核心马桶人永久拥有；等级提供稳定数值成长，星级解锁主动技能、被动技能、技能质变与一个工厂专长。战斗失败不降低永久角色状态。
- acceptance_criteria: 角色拥有稳定 hero_id、level、star、xp 和技能解锁状态；升级消耗金币与工厂材料，并通过唯一成长函数同时更新等级、经验、基础属性和正向 `ΔCP`；升星消耗碎片或突破资源；星级节点至少包含战斗能力和工厂专长，且同一成长结果可被 UI 清楚预览。
- implementation_reference: project-a/game/scripts/state/hero_state.gd, project-a/game/scripts/domain/progression/hero_progression.gd, project-a/game/scripts/domain/factory/logistics_service.gd, project-a/game/scripts/domain/progression/combat_power.gd
- verification_evidence: project-a/tools/run_balance_tests.gd, project-a/tools/run_slg_loop_tests.gd
- conflict_references: project-a/game/scripts/state/hero_state.gd, project-a/game/scripts/state/factory_state.gd
- handoffs: GC-003, GC-004
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 建立永久角色成长权威，迁移可复用旧英雄字段并移除库存实例永久阵亡语义
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 永久身份、统一等级成长、二至三星节点、稳定技能解锁 ID、主动技能三级研究与工厂专长派驻已接通；
  战役与招募已统一使用单调角色索引分配，交错解锁不会复用 hero ID。完整 25 关经济可达性与真人理解仍待验证。
- last_updated: 2026-07-26
- last_verified: —

## GC-003: 工厂后勤与设施
- owner: game-design
- status: accepted
- accepted_intent: 工厂以进度事件逐步取得建筑资格，持续生产陶瓷、零件和能源等后勤资源；研究所把关键战果转化为确定性永久援军和角色研究，不生产或消耗库存单位。
- acceptance_criteria: 建筑至少具有 locked、eligible、built 三态；未满足进度时资源不能提前建造；首次 1-4 失败后只开放研究所建造资格，玩家主动建成后开放一次免费研究突破十连，固定获得冲锋与装甲两名永久援军，且不消耗招募券、不推进长期保底、不可重复领取；资源生产、建造、升级和领取 exact-once，刷新不丢失。
- implementation_reference: project-a/game/scripts/domain/factory/logistics_service.gd, project-a/game/scripts/domain/recruitment/research_breakthrough_service.gd, project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd, project-a/tools/run_research_breakthrough_tests.gd
- conflict_references: project-a/game/scripts/domain/factory/factory_service.gd, project-a/game/scripts/state/factory_state.gd
- handoffs: GC-004, GC-005
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 保留命令幂等边界，以后勤资源生产支持永久成长；研究只解锁或强化永久角色
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 新入口已实现六座可点击 3D 建筑、5×5 有界放置和后勤服务；研究所已接通 locked、eligible、built 三态，
  1-4 首败只开放资格，玩家主动建成后可领取一次免费研究突破十连，冲锋与装甲确定性永久入列，
  十连不触碰长期招募保底。量产兵和兵工厂单位订单属于已取消旧方向，不是待实现项。
- last_updated: 2026-07-27
- last_verified: —

## GC-004: 城镇攻坚与无损结算
- owner: game-design
- status: accepted
- accepted_intent: 永久主力军团主动攻打未占领城镇；战斗内 HP、阵亡、治疗和撤退决定本局胜负，但结算后永久角色保持 100% 可出征，不产生维修成本或等待。
- acceptance_criteria: 关卡开始前展示威胁、推荐战力、当前编队能力比与预计本局风险；结算展示收益和战斗复盘；胜利、失败、撤退和重复结算都不得降低永久角色状态或创建维修订单。
- implementation_reference: project-a/game/scripts/domain/factory/logistics_service.gd, project-a/game/scripts/commands/command_executor.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd
- conflict_references: —
- handoffs: GC-005, GC-006
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 删除玩家可达的旧维修语义，并保留旧字段只用于存档迁移归一化
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 当前运行时、主循环、生命周期与兼容回归已统一为战后完全无损；真人是否理解失败后的
  成长与再战选择仍待验证。
- last_updated: 2026-07-26
- last_verified: —

## GC-005: 经济分层与反死锁
- owner: game-design
- status: accepted
- accepted_intent: 工厂产基础工业资源，城镇战斗产金币、工业技术和受控突破资源；基础资源与战果共同形成角色和设施的永久成长，且不自我增殖。
- acceptance_criteria: 同一种资源不得在同一闭环中同时作为主要投入与更高数量的稳定产出；每笔工业资源消耗都形成永久成长；玩家资源不足时仍可通过工厂最低产能和可重复战果恢复下一次有意义的成长选择。
- implementation_reference: project-a/game/scripts/state/economy_state.gd, project-a/game/scripts/domain/factory/logistics_service.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd
- conflict_references: project-a/game/scripts/state/economy_state.gd, project-a/game/scripts/domain/economy/economy_valuation.gd
- handoffs: GC-003, GC-004
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 建立工业资源、战争资源和突破资源账本，删除图纸抽取作为 P0 核心经济
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 新玩家入口只暴露工业资源、金币和技术；旧兼容字段尚留在 schema v8 迁移外壳内但不可达。
- last_updated: 2026-07-26
- last_verified: —

## GC-006: 首个重构切片与 UX
- owner: producer
- status: accepted
- accepted_intent: 第一切片用“Gman 单人连胜—1-4 撞墙—研究所—免费突破十连—永久援军编队—反攻—资源设施投产—自主升星—1-5 Boss”证明战争需求驱动工厂、工厂产出供养永久军团、军团再回到战场。
- acceptance_criteria: 新档只有 Gman；单人稳定通过 1-1 至 1-3、首次 1-4 稳定失败；之后主动建研究所并固定获得冲锋与装甲，三人稳定攻克 1-4；玩家再选择并建成一种资源设施、收取首批真实后勤，在至少两条经济可达成长路线中选择其一并稳定攻克 1-5；不得用强制挂机等待首批产出；模型时间不超过 30 分钟，844×390 下目标、门禁、阵位、炮击机制和恢复路径可读。
- implementation_reference: project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_first_chapter_balance_scan.gd, project-a/tools/run_first_30m_journey_tests.gd, project-a/tools/run_research_breakthrough_tests.gd, project-a/tools/run_ui_smoke_tests.gd
- conflict_references: project-a/scripts/main.gd, project-a/scenes/screens/main.tscn
- handoffs: GC-001, GC-002, GC-003, GC-004, GC-005
- handoff_from: producer
- handoff_to: programming
- handoff_request: 维护新档状态机、首败分支、免费突破、三人反攻、自主成长、Boss 决战和 Web 验证
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 7-seed 战斗扫描和 14 条默认手动技能的干净新档旅程已证明规则、工厂首批后勤、经济可达性、手动操作路径与存档恢复；冲锋靠预警爆发压制，装甲靠预警护盾承炮反震。尚缺 5 名目标玩家
  盲测，不能由自动证据宣称节奏、Boss 可读性或继续游玩意愿达标。
- last_updated: 2026-07-27
- last_verified: —

## GC-007: 范围与发布门槛
- owner: producer
- status: accepted
- accepted_intent: 当前只做永久角色、后勤资源、研究解锁、六槽编队和主动攻城；保留现有 5×5 有界设施选址，但不扩展道路、工人或复杂物流；继续不做量产单位、图纸抽取、自动扫荡、PvP、公会、多队大地图和真实支付。游戏内永久英雄招募不等于商业支付授权，商业部署仍受 IP、素材、支付、隐私和目标地区合规约束。
- acceptance_criteria: 任何被延期系统进入制作前必须证明它强化当前核心循环且不替代主动攻城；真实商业发布必须具备书面授权、素材来源、支付权益账本、未成年人保护、隐私与退款证据。
- implementation_reference: —
- verification_evidence: —
- conflict_references: —
- handoffs: —
- handoff_from: —
- handoff_to: —
- handoff_request: —
- handoff_allowed_fields: —
- handoff_blocking: —
- deviation: 等待核心循环真人验证与商业前置条件。
- last_updated: 2026-07-27
- last_verified: —

## GC-008: 数值可解释性与商业化前置度量
- owner: game-design
- status: accepted
- accepted_intent: 使用统一单位解释当前编队战力、关卡能力比、工业资源时间价值、永久成长效率、内容寿命和未来商品影响；保持独立资源门禁，不用固定全局汇率、账号总战力或页面私有公式掩盖问题。
- acceptance_criteria: 策划评审能给出 `CP_formation`、`CP_stage`、能力比、挑战/推荐线、FM/TFA/FL、资源压力、成本/`ΔCP`、经济可达关卡和下一可见成长事件；工厂金币能力明确区分直接产出与出征支持的间接获取；新乘区、货币和商品通过通胀、死锁、内容寿命及非付费可达性审查；所有结论标注 implemented、derived、target、playtest hypothesis、measured 或 unknown。
- implementation_reference: docs/references/product-design/game-state-measurement-framework.md, project-a/game/scripts/domain/progression/war_readiness_report.gd, project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_balance_tests.gd, project-a/tools/run_ui_smoke_tests.gd, python3 tools/docs_lint.py
- conflict_references: project-a/scripts/slg_main.gd, project-a/game/scripts/domain/content/stage_catalog.gd
- handoffs: GC-003, GC-004, GC-005, GC-006
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 后续配置与仪表盘使用本框架的稳定单位；确定性扫描和真人试玩校准阈值，商业化不得先于非付费闭环成立
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 当前代码已有统一指挥情报页；新档唯一 Gman 的前三关采用 `1950/2000/2020` 推荐线，1-4 真实三人编队采用 `5700`。2026-07-27 的 7-seed 扫描证明：1-3 为 51.6–69.2 秒险胜且结束生命为 5.6%–32.8%，1-4 单人全败且三人全胜；1-5 基础三人全败，冲锋升星与装甲升星两条命名路线分别全胜。当前 1-5 页面 `6500` 可作为自动校准候选，但真人可读性、完整经济可达性和 25 关新档路径仍未验证。
- last_updated: 2026-07-26
- last_verified: 2026-07-26

## GC-009: 长期进度、免费战令、招募与成就
- owner: game-design
- status: accepted
- accepted_intent: 在工厂与主动攻城核心闭环之上加入行动任务、指挥官等级、28 天免费战令、永久成就和游戏内招募券驱动的永久英雄招募；五系统共享原始玩法事件与 exact-once 账本，核心角色和通关必需职责保持确定性可得。
- acceptance_criteria: 首章按 Lv2/3/4/5 渐进开放任务、成就、招募和战令；任务不要求抽卡或付费；战令 30 级并有缺勤容错；招募公开概率、十抽 A、60 抽 S 与定向继承；重复英雄转可用数据；系统间不得通过领奖事件形成奖励循环；工厂与攻城贡献至少约 65% 实质成长。
- implementation_reference: docs/references/product-design/meta-progression-system.md, project-a/game/scripts/state/meta_progression_state.gd, project-a/game/scripts/domain/meta/meta_progression_service.gd, project-a/game/scripts/domain/recruitment/signal_recruit_service.gd, project-a/scripts/slg_main.gd
- verification_evidence: godot --headless --path project-a --script res://tools/run_meta_progression_tests.gd, godot --headless --path project-a --script res://tools/run_ui_smoke_tests.gd
- conflict_references: project-a/game/scripts/domain/quest/quest_catalog.gd, project-a/game/scripts/domain/achievement/achievement_catalog.gd, project-a/game/scripts/domain/economy/blueprint_draw_service.gd
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-008
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 先建立共享事件和指挥官状态，再迁移任务成就、免费战令与永久英雄招募；不得直接恢复旧图纸材料混池
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 领域状态、事务、v5/v6/v7→v8 迁移和 App Shell 已实现；任务、成就、招募、战令按关卡与等级双条件开放，目标页三标签、顶层待领取计数、完整 30 级奖励轨和批量领奖已接通；招募新英雄可部署到六槽编队，重复英雄专属数据可优先用于升星；招募结果与编队编辑的 844×390 本机渲染已验证；时间加速已覆盖跨日、跨周、跨赛季自动补发和保底保留，真实 28 天行为、移动设备浏览器、真人周期体验和数值平衡仍待验证。
- last_updated: 2026-07-26
- last_verified: 2026-07-26

## GC-010: 玩家优先与乐趣门槛
- owner: producer
- status: accepted
- accepted_intent: 所有系统、数值、美术和 UI 首先服务玩家的理解、选择、张力、反馈与继续游玩的欲望；自动测试、页面数量、功能数量和计划完成度都不能替代“好玩”。
- acceptance_criteria: 首 30 分钟形成三次可辨认的乐趣峰值——Gman 单人推进的爽感、1-4 失败后带援军反攻的逆转感、玩家自主选择援军升星后击破 1-5 的成就感；至少 5 名未接触项目的目标玩家完成 20–30 分钟盲测，至少 4 人无需口头提示完成核心闭环，至少 4 人能解释 1-4 失败与成长选择，至少 3 人主动表达继续游玩意愿；任何主要段落连续 90 秒没有新判断、有效操作、清晰反馈或期待兑现即视为节奏缺陷。
- implementation_reference: docs/references/constraints/first-30m-contract.md, docs/references/product-design/competitor-first-session-benchmark.md, project-a/game/scripts/domain/content/stage_catalog.gd, project-a/game/scripts/domain/onboarding/onboarding_catalog.gd
- verification_evidence: 目标玩家盲测录像/观察记录、试玩报告、访谈结论；自动测试只能作为辅助正确性证据
- conflict_references: 任何只以 headless 通过、截图齐全、功能数量或 30 分钟时长宣称完成的结论
- handoffs: GC-004, GC-006, GC-008
- handoff_from: producer
- handoff_to: game-design
- handoff_request: 每轮实现先说明它创造哪种玩家感受和哪项有意义选择，再用真人行为判断保留、重做或删除
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated,last_verified
- handoff_blocking: true
- deviation: 当前自动证据已证明首章规则台阶和两条 Boss 成长路线；首章行动已改为随领域结果
  exact-once 自动结算奖励并直接暴露下一真实行动，删除七次无意义领奖门禁；行动六加入资源设施
  投产与首批后勤收取，使工厂产出在 Boss 前真正进入军团成长闭环；默认手动技能旅程要求玩家
  在 Boss 预警中作出时机判断，冲锋打断、装甲承炮反震形成两种可见解法；装甲成功时已有
  世界内文字/形状、独立音效和结算复盘，低画质与减少动态保留语义。尚无目标玩家盲测，
  因此不能宣称首 30 分钟好玩或达到上线质量。
- last_updated: 2026-07-27
- last_verified: —

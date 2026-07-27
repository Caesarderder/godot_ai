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
- acceptance_criteria: 首局连续完成 Gman 单人前三关、1-4 首败、信号招募免费接收基础图纸十连、研究所逐张研发冲锋与装甲、两名永久角色入列、三人编队和 1-4 反攻，再自主选择一条成长路线攻克 1-5；角色不得永久删除，关键路径不得因资源、失败或抽卡死锁。
- implementation_reference: project-a/scripts/slg_main.gd, project-a/game/scripts/commands/command_executor.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd
- conflict_references: docs/game-contract.md@contract_version-1, project-a/game/scripts/state/game_state.gd
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-006
- handoff_from: producer
- handoff_to: programming
- handoff_request: 以永久角色、工厂后勤资源、设施三态、信号图纸、研究所定向研发、六槽编队和主动攻城为运行时权威；不得恢复量产兵或材料混池抽取
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 运行时与首章合同已切换到“信号图纸 → 研究所研发 → 唯一永久角色”路线；量产兵、研究所抽卡和三前排旧方向已明确取消，
  不再作为缺失功能。浏览器存档已支持状态提示、JSON 下载、严格校验、进度预览和二次确认恢复。
- last_updated: 2026-07-27
- last_verified: —

## GC-002: 永久角色、等级与星级
- owner: game-design
- status: accepted
- accepted_intent: 每名核心马桶人永久拥有；等级提供稳定数值成长，星级解锁主动技能、被动技能、技能质变与一个工厂专长。战斗失败不降低永久角色状态。
- acceptance_criteria: 角色拥有稳定 hero_id、level、star、xp、B/A/S 评级和技能解锁状态；军团图鉴展示全部角色及“未获图纸、图纸待研发、已研发入列”状态。等级升级要求该角色达到战斗经验阈值并消耗金币；升星统一消耗军团数据；技能研究消耗金币与军团数据并受研究所等级门槛约束。角色成长不得消耗工业材料。
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
- accepted_intent: 工厂以进度事件逐步取得建筑资格，所有资源产线统一生产工业材料；研究所把信号图纸转化为确定性永久援军和角色研究，不生产或消耗库存单位。
- acceptance_criteria: 建筑至少具有 locked、eligible、built 三态；首次 1-4 失败后开放研究所建造资格和一次免费的基础图纸信号十连，十连位于信号招募页，只形成冲锋/装甲两张完整设计图纸与八张同型号设计分图，不直接授予角色、不发资源、不推进长期保底；研究所只消费已拥有图纸和时间，研发完成后才授予对应唯一永久角色。首章首次设施施工统一为 5 秒；资源生产、建造、研发、升级和领取 exact-once。
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
  1-4 首败开放基础信号与研究所资格；信号十连确定性入库冲锋/装甲图纸，研究所逐张研发后两名
  永久角色才入列。长期信号招募只产 B/A/S 图纸，重复图纸转军团数据。量产兵和单位订单属于已取消旧方向。
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
- accepted_intent: 当前玩家只管理金币、军团数据、工业材料、招募券四种可消费核心资源。金币与军团数据服务角色成长，工业材料只服务设施建造与升级，招募券只服务信号招募；战斗经验与设计图纸是进度/解锁条件，不是通用货币。
- acceptance_criteria: 角色升级消耗金币并检查战斗经验，升星消耗军团数据，技能研究消耗金币与军团数据；设施建造与升级只消耗工业材料；信号招募只消耗招募券。常规战斗不直接掉落工业材料。旧工业技术、技能芯片、陶瓷/零件/能源分账、专属英雄数据和重复图纸数据通过 schema v9 一次性归并，之后当前命令、奖励、成本和 UI 不得再读写这些旧账本。
- implementation_reference: project-a/game/scripts/state/economy_state.gd, project-a/game/scripts/domain/factory/logistics_service.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd
- conflict_references: project-a/game/scripts/state/economy_state.gd, project-a/game/scripts/domain/economy/economy_valuation.gd
- handoffs: GC-003, GC-004
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 建立工业资源、战争资源、角色成长资源和设计图纸账本；信号只负责图纸，研究所只负责研发
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 四资源权威账本复用 `toilet_coins`、`hero_shards`、`factory.materials.porcelain` 与 `recruit_tickets`；旧字段只留作 schema v9 兼容壳并保持为零。工业材料折算按旧产线分钟归一化，军团数据按旧芯片购买力归并；首章金币余额仍偏松，等待第二章完整经济扫描后再做独立调参。
- last_updated: 2026-07-26
- last_verified: —

## GC-006: 首个重构切片与 UX
- owner: producer
- status: accepted
- accepted_intent: 第一切片用“Gman 单人连胜—1-4 撞墙—信号图纸十连—研究所定向研发—永久援军编队—反攻—自主升星—资源设施投产—1-5 Boss”证明角色成长与工业扩张是相邻但不混用成本的双线循环。
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
- accepted_intent: 当前只做永久角色、后勤资源、信号图纸、研究所定向研发、六槽编队、B/A/S 图鉴和主动攻城；保留现有 5×5 有界设施选址，但不扩展道路、工人或复杂物流；继续不做量产单位、研究所抽卡、自动扫荡、PvP、公会、多队大地图和真实支付。
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
- acceptance_criteria: 策划评审能给出 `CP_formation`、`CP_stage`、能力比、挑战/推荐线、IM/TFA/IL、资源压力、成本/`ΔCP`、经济可达关卡和下一可见成长事件；工厂金币能力明确区分直接产出与出征支持的间接获取；新乘区、货币和商品通过通胀、死锁、内容寿命及非付费可达性审查；所有结论标注 implemented、derived、target、playtest hypothesis、measured 或 unknown。
- implementation_reference: docs/references/product-design/game-state-measurement-framework.md, project-a/game/scripts/domain/progression/war_readiness_report.gd, project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_balance_tests.gd, project-a/tools/run_progression_cycle_scan.gd, project-a/tools/run_ui_smoke_tests.gd, python3 tools/docs_lint.py
- conflict_references: project-a/scripts/slg_main.gd, project-a/game/scripts/domain/content/stage_catalog.gd
- handoffs: GC-003, GC-004, GC-005, GC-006
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 后续配置与仪表盘使用本框架的稳定单位；确定性扫描和真人试玩校准阈值，商业化不得先于非付费闭环成立
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 当前代码已有统一指挥情报页；新档唯一 Gman 的前三关采用 `1950/2000/2020` 推荐线，1-4 真实三人编队采用 `5700`。2026-07-27 的 7-seed 扫描证明：1-3 为 51.6–69.2 秒险胜且结束生命为 5.6%–32.8%，1-4 单人全败且三人全胜；1-5 基础三人全败，冲锋升星与装甲升星两条命名路线分别全胜。当前 1-5 页面 `6500` 可作为自动校准候选。首章后按玩家“卡点过密”反馈把墙收束到每章 Boss：推荐线从 2-1 起采用 `6900/7300/7700/8100/9000/9400/9800/10200/10600/11500`；保守资源消费后的 7 seed 首轮连续通过 2-1 至 2-4，在 2-5 把核心削至 50.80%–81.69% 后全败；再次成长后连续通过 2-5 至 3-4、在 3-5 全败。主动技能研究也已进入统一战力口径。真人对新卡点密度的感受、其余关卡完整经济可达性和 25 关新档路径仍未验证。
- last_updated: 2026-07-26
- last_verified: 2026-07-26

## GC-009: 长期进度、免费战令、招募与成就
- owner: game-design
- status: accepted
- accepted_intent: 在工厂与主动攻城核心闭环之上加入行动任务、指挥官等级、28 天免费战令、永久成就、游戏内招募券驱动的 B/A/S 设计图纸信号招募，以及首章完成后的一次性新游福利；图纸必须经研究所研发才成为永久角色。
- acceptance_criteria: 首章按 Lv2/3/4/5 渐进开放任务、成就、招募和战令；任务不要求抽卡或付费；战令 30 级并有缺勤容错；招募公开概率、十抽 A、60 抽 S 与定向继承；重复图纸转军团数据；1-5 后福利只可领取一次，特殊升星核心仅可替代一次 1★→2★ 所需的 4 份军团数据，工业材料从不参与角色升星，后勤箱固定发放 25 工业材料；福利不得破坏既定推进窗；系统间不得通过领奖事件形成奖励循环。
- implementation_reference: docs/references/product-design/meta-progression-system.md, project-a/game/scripts/state/meta_progression_state.gd, project-a/game/scripts/domain/meta/meta_progression_service.gd, project-a/game/scripts/domain/meta/new_player_welfare_service.gd, project-a/game/scripts/domain/recruitment/signal_recruit_service.gd, project-a/scripts/slg_main.gd
- verification_evidence: godot --headless --path project-a --script res://tools/run_meta_progression_tests.gd, godot --headless --path project-a --script res://tools/run_new_player_welfare_tests.gd, godot --headless --path project-a --script res://tools/run_progression_cycle_scan.gd, godot --headless --path project-a --script res://tools/run_ui_smoke_tests.gd
- conflict_references: project-a/game/scripts/domain/quest/quest_catalog.gd, project-a/game/scripts/domain/achievement/achievement_catalog.gd, project-a/game/scripts/domain/economy/blueprint_draw_service.gd
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-008
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 先建立共享事件和指挥官状态，再迁移任务成就、免费战令与设计图纸信号招募；不得恢复直接抽英雄或图纸材料混池
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 领域状态、事务、v5/v6/v7/v8→v9 迁移和 App Shell 已实现；任务、成就、招募、战令按关卡与等级双条件开放，目标页三标签、顶层待领取计数、完整 30 级奖励轨和批量领奖已接通；图纸研发出的新英雄可部署到六槽编队，重复图纸转军团数据。1-5 后一次性“黑市援助”已接入行动页、军团页和持久账本；核心替代军团数据、后勤箱补充工业材料，两个用途不再混淆。四资源重构后的完整推进扫描和真人周期体验仍待验证。
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
  exact-once 自动结算奖励并直接暴露下一真实行动，删除七次无意义领奖门禁；行动六先用战斗获得
  的英雄数据完成升星，再独立建设并收取资源设施，使“角色成长”和“工业扩张”在同一教学中可比较
  但不共用成本；默认手动技能旅程要求玩家
  在 Boss 预警中作出时机判断，冲锋打断、装甲承炮反震形成两种可见解法；装甲成功时已有
  世界内文字/形状、独立音效和结算复盘，低画质与减少动态保留语义。尚无目标玩家盲测，
  因此不能宣称首 30 分钟好玩或达到上线质量。
- last_updated: 2026-07-27
- last_verified: —

---
contract_version: 11
project_id: toilet-factory-siege
last_updated: 2026-07-29
km_id: reference.game-contract
km_type: reference
domain: product
status: active
owner: maintainers
last_verified: 2026-07-28
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
  - reference.campaign-60-stage-progression
---

# 马桶人工厂攻城项目契约

本文件是制作人、策划、程序、美术、音频和测试共享的项目级状态源。详细规则由
[主 GDD](references/product-design/skibidi-toilet-idle-siege-gdd.md) 维护；当前代码事实由
[实现状态](references/constraints/implementation-status.md) 维护。

## GC-010: 五章 60 关、双卡点与原作感战役
- owner: game-design
- status: accepted
- accepted_intent: 首 30 分钟的 1-1～1-5 保持不变；之后以每章 12 关扩大战役，每三关形成“两个轻关+一个精英”的循环，每章 6 为战力墙、9 为专项科技墙、12 为章节 Boss。章节情绪参考原作从 Camera 抵抗、Speaker/寄生危机、TV 技术战、联盟反攻到科学家基地决战的宏观演进，但不复制镜头、对白、音乐或资产。
- acceptance_criteria: 60 个稳定关卡 ID 和独立名称；3/6/9 精英、12 Boss；检查点小奖励与精英/Boss 大奖励；每章一项工业材料专项科技；未研发可硬打但明显困难，研发后机制伤害至少降低 60%；福利不能让新玩家跳过新增墙；旧 1-1～1-5 自动证据继续通过；商业发行前取得 IP 书面授权。
- implementation_reference: docs/references/product-design/campaign-60-stage-progression.md, project-a/game/scripts/domain/content/stage_catalog.gd, project-a/game/scripts/domain/battle/battle_session.gd
- verification_evidence: project-a/tools/run_campaign_60_stage_tests.gd, project-a/tools/run_campaign_tests.gd, project-a/tools/run_battle_tests.gd
- conflict_references: docs/game-contract.md@contract_version-10
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-007, GC-008
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 以配置驱动的关卡层级和反制科技替换五关制硬编码，并保留命令、存档与战斗确定性
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 60 关目录、五项科技、durable 研发命令、战斗机制减伤和战区入口已实现；完整 60 关经济可达性与真人剧情识别仍需持续扫描和盲测。
- last_updated: 2026-07-29
- last_verified: 2026-07-29

## GC-001: 玩家承诺与核心循环
- owner: producer
- status: accepted
- accepted_intent: 玩家从唯一永久英雄 Gman 开始，通过主动攻城暴露职责缺口，再把战果转化为研究所、确定性永久援军、编队调整和自主成长，逐步把地下工厂经营成支撑永久军团的战争机器。
- acceptance_criteria: 首局先建设研究所，再由 Gman 推进前三关；1-2、1-3 首通分别固定获得冲锋与装甲图纸，研究所逐张研发后两名永久角色入列，三人编队完成 1-4 反攻并自主选择一条成长路线攻克 1-5；免费十连只在信号招募功能正式解锁后开放，不承担首批通关必需角色供给；角色不得永久删除，关键路径不得因资源、失败或抽卡死锁。
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
- acceptance_criteria: 角色拥有稳定 hero_id、level、star、xp、B/A/S 评级和技能解锁状态；军团图鉴与科技树展示全部角色及“未获图纸、图纸待研发、已研发入列”状态，并明确评级、阵营、职责、1★完整价值、2★/3★质变和图纸来源。等级升级要求该角色达到战斗经验阈值并消耗金币；升星只消耗该型号专属碎片；技能研究消耗金币与军团数据并受研究所等级门槛约束。角色成长不得消耗工业材料。
- implementation_reference: project-a/game/scripts/state/hero_state.gd, project-a/game/scripts/domain/progression/hero_progression.gd, project-a/game/scripts/domain/factory/logistics_service.gd, project-a/game/scripts/domain/progression/combat_power.gd, project-a/game/scripts/ui/blueprint_screen.gd, .codex/skills/toilet-character-production/SKILL.md
- verification_evidence: project-a/tools/run_balance_tests.gd, project-a/tools/run_slg_loop_tests.gd, project-a/tools/run_blueprint_screen_tests.gd, .codex/skills/toilet-character-production/scripts/test_character_design.py
- conflict_references: project-a/game/scripts/state/hero_state.gd, project-a/game/scripts/state/factory_state.gd
- handoffs: GC-003, GC-004
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 建立永久角色成长权威，迁移可复用旧英雄字段并移除库存实例永久阵亡语义
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 永久身份、统一等级成长、二至三星节点、稳定技能解锁 ID、主动技能三级研究与工厂专长派驻已接通；
  战役与招募已统一使用单调角色索引分配，交错解锁不会复用 hero ID。2026-07-28 科技树删除错误前置箭头并补齐评级、阵营、职责、星级质变与来源；持续新增角色改由仓库 Skill 按当前代码事实和关卡替代路线校验。完整 60 关真人理解仍待验证。
- last_updated: 2026-07-28
- last_verified: —

## GC-003: 工厂后勤与设施
- owner: game-design
- status: accepted
- accepted_intent: 工厂以进度事件逐步取得建筑资格；基础资源产线统一生产工业材料，2-5 首通后可建设金币铸造厂，把后期工业扩张转化为持续金币收入；研究所把信号图纸转化为确定性永久援军和角色研究，不生产或消耗库存单位。
- acceptance_criteria: 建筑至少具有 locked、eligible、built 三态；新档直接取得研究所建造资格，但必须由玩家主动选址、施工和验收；金币铸造厂在第二章最终 Boss 2-12 首通后取得资格，消耗 60 工业材料，Lv.1 每小时生产 30 金币、随等级线性增长并最多离线累计 12 小时，单栋与全部领取均 exact-once；初始 20 金币与 30 工业材料只支持研究所开工，后续资源按研究所落成、1-3 首通、1-5 首通三个里程碑通过手动礼包领取；1-2、1-3 首通分别固定入库冲锋与装甲图纸，不直接授予角色；研究所消费已拥有图纸和时间，研发完成后才授予对应唯一永久角色；重复图纸转为该型号专属碎片，供已解锁角色升星。免费十连位于信号招募页，且只有信号招募正式解锁后开放，并推进同一长期保底。调试阶段所有设施建造、设施升级和蓝图研发统一为 5 秒；资源生产、建造、研发、升级和礼包领取 exact-once。
- implementation_reference: project-a/game/scripts/domain/factory/logistics_service.gd, project-a/game/scripts/domain/meta/starter_gift_service.gd, project-a/game/scripts/domain/recruitment/research_breakthrough_service.gd, project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_slg_loop_tests.gd, project-a/tools/run_research_breakthrough_tests.gd, project-a/tools/run_starter_gift_tests.gd
- conflict_references: project-a/game/scripts/domain/factory/factory_service.gd, project-a/game/scripts/state/factory_state.gd
- handoffs: GC-004, GC-005
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 保留命令幂等边界，以后勤资源生产支持永久成长；研究只解锁或强化永久角色
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 新入口已实现六座可点击 3D 建筑、5×5 有界放置和后勤服务；研究所已接通 eligible、built 状态并在新档开放建造，
  1-2、1-3 首通确定性入库冲锋/装甲图纸，研究所逐张研发后两名永久角色才入列。2-5 首通后解锁金币铸造厂，真实接入网格建造、离线计时、金币账本、单栋/全部领取与存档。免费十连与长期信号招募统一在招募功能解锁后出现；
  信号只产 B/A/S 图纸；长期重复图纸目标改为型号专属碎片，当前代码尚待本轮迁移完成。量产兵和单位订单属于已取消旧方向。
- last_updated: 2026-07-29
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
- accepted_intent: 当前玩家只管理金币、军团数据、工业材料、招募券四种可消费核心资源。金币由战斗、里程碑与后期金币铸造厂提供，并与军团数据共同服务角色成长；工业材料只服务设施建造与升级，招募券只服务信号招募；战斗经验与设计图纸是进度/解锁条件，不是通用货币。
- acceptance_criteria: 角色升级消耗金币并检查战斗经验；长期升星只消耗该角色型号的专属碎片，教学核心可以 exact-once 免除一次 1★→2★ 碎片成本；技能研究仍消耗金币与受控研究数据；设施建造与升级只消耗工业材料，2-5 后的金币铸造厂可以把时间转化为金币但不改变设施成本；信号招募只消耗招募券，首章完成免费十连除外。常规战斗不直接掉落工业材料。schema v11 必须新增专属碎片账本而不把无法追溯来源的旧通用数据伪造成任一角色碎片。
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
- accepted_intent: 第一切片用“先建研究所—Gman 推进—1-2/1-3 获取角色图纸—研究所定向研发—1-4 撞墙—永久援军编队反攻—自主升星—资源设施投产—1-5 Boss—解锁信号招募免费十连”证明确定性主线角色与长期招募彼此分离。
- acceptance_criteria: 新档只有 Gman、20 金币与刚好可建研究所的 30 工业材料；单人稳定通过 1-1 至 1-3，研究所落成与 1-3 首通分别解锁可手动领取的新手/新游礼包；1-2、1-3 首通分别获得冲锋与装甲图纸；研究所完成两张图纸后形成三人编队并稳定攻克 1-4；玩家再选择并建成一种资源设施、收取首批真实后勤，在至少两条经济可达成长路线中选择其一并稳定攻克 1-5，随后解锁开服庆典礼包；信号招募解锁后才出现免费十连；不得用强制挂机等待首批产出；模型时间不超过 30 分钟，844×390 下目标、礼包、门禁、阵位、炮击机制和恢复路径可读。
- implementation_reference: project-a/scripts/slg_main.gd, project-a/game/scripts/domain/meta/starter_gift_service.gd
- verification_evidence: project-a/tools/run_first_30m_journey_tests.gd, project-a/tools/run_starter_gift_tests.gd, project-a/tools/run_research_breakthrough_tests.gd, project-a/tools/run_ui_smoke_tests.gd
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
- accepted_intent: 使用统一单位解释当前编队战力、关卡能力比、工业资源时间价值、永久成长效率、内容寿命和未来商品影响；保持独立资源门禁，不用固定全局汇率、账号总战力或页面私有公式掩盖问题。同一敌人类型必须使用稳定 archetype 和同一套基础战斗数值，不得因所在关卡不同暗改生命、攻击、防御、射程或攻速；关卡难度改由敌人编成、结构、机制和明确命名的新敌人类型承担。
- acceptance_criteria: 策划评审能给出 `CP_formation`、`CP_stage`、能力比、挑战/推荐线、IM/TFA/IL、资源压力、成本/`ΔCP`、经济可达关卡和下一可见成长事件；同一敌人 archetype 在所有出现关卡的 HP、攻击、防御、射程和攻速完全一致，数值职责变化必须改用玩家可辨认的新名称与 archetype；工厂金币能力明确区分直接产出与出征支持的间接获取；新乘区、货币和商品通过通胀、死锁、内容寿命及非付费可达性审查；所有结论标注 implemented、derived、target、playtest hypothesis、measured 或 unknown。
- implementation_reference: docs/references/product-design/game-state-measurement-framework.md, project-a/game/scripts/domain/progression/war_readiness_report.gd, project-a/scripts/slg_main.gd
- verification_evidence: project-a/tools/run_balance_tests.gd, project-a/tools/run_progression_cycle_scan.gd, project-a/tools/run_ui_smoke_tests.gd, python3 tools/docs_lint.py
- conflict_references: project-a/scripts/slg_main.gd, project-a/game/scripts/domain/content/stage_catalog.gd
- handoffs: GC-003, GC-004, GC-005, GC-006
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 后续配置与仪表盘使用本框架的稳定单位；确定性扫描和真人试玩校准阈值，商业化不得先于非付费闭环成立
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 当前代码已有统一指挥情报页；新档唯一 Gman 的前三关采用 `1950/2000/2020` 推荐线，1-4 真实三人编队采用 `5700`。旧 1-1～1-5 自动基线继续通过。2026-07-29 起战役改为五章 60 关，每章 3/6/9/12 分别承担精英、战力墙、科技墙和 Boss 节拍；推荐线与敌方倍率由 `StageCatalog` 统一生成。第二章已有增援/双塔组合，第三章已有信号消失、真实换位、有限控制、监军护盾，第四章已有显式标记、防空、临时单位净化与模块轮换。60 关使用独立遭遇名；完整经济可达性和真人卡点密度仍未验证。
- last_updated: 2026-07-26
- last_verified: 2026-07-26

## GC-009: 长期进度、免费战令、招募与成就

- owner: game-design
- status: accepted
- accepted_intent: 在工厂与主动攻城核心闭环之上加入行动任务、指挥官等级、28 天免费战令、永久成就、游戏内招募券驱动的 B/A/S 设计图纸信号招募，以及首章完成后的阵营起手十连；玩家由抽取到的角色池、研究顺序、专属碎片升星与编队形成自己的长期阵营玩法，图纸必须经研究所研发才成为永久角色。
- acceptance_criteria: 首章按 Lv2/3/4/5 渐进开放任务、成就、招募和战令；任务不要求抽卡或付费；战令 30 级并有缺勤容错；招募公开概率、十抽 A、60 抽 S 与定向继承；首章完成免费十连使用同一概率与保底、保证两个同评级、不同阵营的新型号候选及两者各自足够升至2★的专属碎片，候选卡必须基于真实永久名册点名已有同阵营搭档或说明将补足的战术，不得承诺隐藏加成；玩家必须依据打法亲自选择其中一个长期阵营核心，S 可作为额外惊喜但不得成为候选间的显性稀有度答案；重复图纸只转该型号专属碎片；B/A/S 的 2★需求分别为 20/30/40 专属碎片，3★需求分别为 40/60/80；S 级一星即拥有完整技能并具备约 A 级二星的基础强度；特殊升星核心只可替代一次 1★→2★ 的目标型号碎片，工业材料从不参与角色升星；十连后的核心选择、研发、编队、三场实战证明、2★质变和 2-5 验证必须从持久事实恢复为唯一主目标，刷新或后续普通招募不得丢失阵营核心；2-5 首通必须激活抽取核心对应的 Tier 1 阵营协议并从 3-1 起产生可见、可复盘的真实效果；3-5 首通必须开放一次 durable 且互斥的 Tier 2 二选一，玩家在“全队协同”和“阵营专精”之间主动决定，未选择时不得自动获得 Tier 2，选择后从 4-1 起真实生效；战斗结算必须显示参战经验以及阵营核心距下一级的真实进度，并只提供一个高优先级因果动作；通用工厂入口不得与具体升星、验证或章节交接竞争，基地仅作为“稍后继续”的次级安全出口；系统间不得通过领奖事件形成奖励循环。
- implementation_reference: docs/references/product-design/meta-progression-system.md, docs/references/product-design/post-30m-faction-progression.md, docs/references/architecture/post-30m-faction-technical-design.md, project-a/game/scripts/state/meta_progression_state.gd, project-a/game/scripts/domain/meta/meta_progression_service.gd, project-a/game/scripts/domain/meta/new_player_welfare_service.gd, project-a/game/scripts/domain/recruitment/signal_recruit_service.gd, project-a/game/scripts/domain/objectives/campaign_objective_projection.gd, project-a/game/scripts/domain/content/faction_catalog.gd, project-a/game/scripts/domain/battle/battle_session.gd, project-a/scripts/slg_main.gd
- verification_evidence: godot --headless --path project-a --script res://tools/run_meta_progression_tests.gd, godot --headless --path project-a --script res://tools/run_new_player_welfare_tests.gd, godot --headless --path project-a --script res://tools/run_progression_cycle_scan.gd, godot --headless --path project-a --script res://tools/run_ui_smoke_tests.gd, godot --headless --path project-a --script res://tools/run_campaign_objective_projection_tests.gd, godot --headless --path project-a --script res://tools/run_post_30m_faction_tests.gd, godot --headless --path project-a --script res://tools/run_post_30m_ui_journey_tests.gd, project-a/artifacts/ui-faction-recruit-result-844x390.png, project-a/artifacts/ui-faction-blueprint-focus-844x390.png, project-a/artifacts/ui-faction-formation-focus-844x390.png, project-a/artifacts/ui-faction-star-unlocked-844x390.png, project-a/artifacts/ui-faction-chapter-two-proof-844x390.png
- conflict_references: project-a/game/scripts/domain/quest/quest_catalog.gd, project-a/game/scripts/domain/achievement/achievement_catalog.gd, project-a/game/scripts/domain/economy/blueprint_draw_service.gd
- handoffs: GC-002, GC-003, GC-004, GC-005, GC-008
- handoff_from: game-design
- handoff_to: programming
- handoff_request: 把长期重复图纸迁移为型号专属碎片，免费十连使用标准保底并形成至少一条新角色升星路线；保留“抽图纸、研究为永久角色”，不得恢复直接抽英雄或图纸材料混池
- handoff_allowed_fields: implementation_reference,status,deviation,last_updated
- handoff_blocking: false
- deviation: 2026-07-28 已完成型号专属碎片账本、重复图纸转换、按稀有度升星成本、免费阵营十连保证、S1 强度、研发/编队/UI/存档接线，并由 7-seed `run_post_30m_faction_tests.gd` 覆盖；免费十连现在保证两个同评级、不同阵营且均可2★的候选，S 只作为标准概率/保底的额外惊喜，`choose_faction_core` 让玩家依据“抢先爆发/承炮续战/后排拆塔/削弱控场”亲自选择长期核心，刷新、普通招募、非法候选和再次选择都不会替换该身份；真实 UI 旅程选择第二候选后才进入其科技分支。同日补齐可从 durable receipt 与领域事实恢复的五阶段阵营目标链，并由 `run_post_30m_ui_journey_tests.gd` 证明真实主场景点击会定向到玩家所选型号的科技分支、空编队槽与同一角色升星；研发领取后的编队首屏同时点名目标空槽、部署后人数与三场实战证明，并把阵营核心排为首个可点候选但不自动上阵。BattleSession 现会分别记录八种型号的 2★质变次数，2-4/2-5 结算把真实参战角色、专属机制和触发次数命名为“阵营质变验证”；领域战斗结算同时公开单人经验与受益人数，结果首屏点名参战阵营核心的当前 XP、下级阈值和尚缺经验，不再把角色成长藏在后台。结算页的通用工厂入口现改为显式 opt-in；2-4 失败只突出精确升星，2-5 胜利只突出第三章新战线，并保留“稍后继续”的次级基地出口。第二章共振从 2-1 的 11 秒/10 能量渐进到 2-4 的 7 秒/18 能量，冲击前有 2 秒可操作预警，HUD 与结算量化真实能量损失。2-3 另有两波可集火广播车，2-4 以黄色预警交替点名前后排，2-5 将有限次支援与声塔并入共振和巨炮终考；机制不再随战斗时长无限叠加。2-5 胜利进一步揭示第三章电视控制威胁，并经唯一 CTA 打开 3-1 所在第三章侦察页；结算同时解锁抽取核心对应的 Tier 1 阵营协议，3-1 起真实产生快攻能量、防线护盾、轰炸标定或干扰虚弱之一。协议从 durable receipt 与 2-5 首通事实派生，不新增可漂移存档字段，HUD 和结算均公开实际影响对象。连续小屏证据证明共振预警、冲击、阵营因果、科技兑现和章节承接可见。真人阵营认同和继续游玩意愿仍待验证，不能由自动测试宣称“好玩”。
- last_updated: 2026-07-28
- last_verified: 2026-07-28

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
  在 Boss 预警中作出时机判断，冲锋打断、装甲承炮反震形成两种可见解法；系统已保证同 tick
  共振不会吞掉已接受的技能请求，并以 2 秒全队爆发窗口把六次重复点卡收束为一次战术命令。
  装甲成功时已有
  世界内文字/形状、独立音效和结算复盘，低画质与减少动态保留语义。尚无目标玩家盲测，
  因此不能宣称首 30 分钟好玩或达到上线质量。
- last_updated: 2026-07-27
- last_verified: —

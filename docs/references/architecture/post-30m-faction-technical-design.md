---
km_id: reference.post-30m-faction-technical-design
km_type: reference
domain: architecture
status: active
owner: gameplay
last_verified: 2026-07-28
source_of_truth:
  - docs/references/product-design/post-30m-faction-progression.md
  - project-a/game/scripts/state/meta_progression_state.gd
  - project-a/game/scripts/domain/recruitment/signal_recruit_service.gd
  - project-a/game/scripts/domain/objectives/campaign_objective_projection.gd
  - project-a/game/scripts/domain/factory/logistics_service.gd
validated_by:
  - godot --headless --path project-a --script tools/run_campaign_objective_projection_tests.gd
  - godot --headless --path project-a --script tools/run_post_30m_faction_tests.gd
  - godot --headless --path project-a --script tools/run_post_30m_ui_journey_tests.gd
  - project-a/artifacts/ui-faction-journey-research-844x390.png
  - project-a/artifacts/ui-faction-recruit-result-844x390.png
  - project-a/artifacts/ui-faction-blueprint-focus-844x390.png
  - project-a/artifacts/ui-faction-formation-focus-844x390.png
  - project-a/artifacts/ui-faction-star-ready-844x390.png
  - project-a/artifacts/ui-faction-star-unlocked-844x390.png
tags:
  - reference:technical-design
  - workflow:post-30m
  - risk:persistence
related:
  - reference.post-30m-faction-progression
  - reference.toilet-factory-technical-design
---

# 30–60 分钟阵营切片技术设计

## 结果与边界

玩家从已完成 1-5 的存档进入军团，领取真实受 seed 影响的免费十连，在两个具备2★碎片的新型号中
通过 durable command 选择一个长期阵营核心，再研发该型号、加入编队，
用该型号的专属碎片完成 2★质变并进入第二章。目标平台保持 Godot 4.6.3、GDScript、
Compatibility、单线程 Web、844×390 横屏。

不新增付费、体力、装备、4★/5★内容、复杂阵营光环或新常驻货币。

## 当前复用

- `SignalRecruitService`：概率、A/S 保底、S 定向和稳定散列。
- `ResearchBreakthroughService`：免费十连 exact-once 入口。
- `FactoryService`：图纸研发订单与永久角色创建。
- `LogisticsService`：角色升星事务和成长 quote。
- `BattleSession`：八型号 2★/3★真实技能质变。
- `MetaProgressionState`：抽数、保底和专属碎片持久状态。
- `CommandExecutor`：唯一写入口、clone、persist-before-success 与 business receipt。
- `LegionScreen`：抽取、图鉴、角色卡、编队与成长投影。
- `CampaignObjectiveProjection`：仅从 durable receipt、角色、编队、星级和关卡首通事实重建
  当前阵营阶段，不增加另一套进度状态。

## 可玩序列

```text
领取免费十连
→ ResearchBreakthroughService 调用标准稳定抽取
→ 首次结果写 discovered_blueprints，重复结果写 hero_fragments[archetype_id]
→ UI 展示新图纸/专属碎片和建议阵营
→ 研究所 start/claim 创建唯一 HeroState
→ 编队命令写入稳定 hero_id
→ star quote 读取该 archetype 的碎片
→ upgrade transaction 原子扣专属碎片、写 star/skill_id
→ BattleSession 从 snapshot 读取 star 并执行质变
→ 第二章结算继续提供可追踪成长
→ CampaignObjectiveProjection 在刷新与跨屏后恢复唯一下一行动
```

## 所有权与数据

| 系统 | 所有状态 | 命令/输入 | 输出 | 失败 |
|---|---|---|---|---|
| `MetaProgressionState` | `hero_fragments: Dictionary[String,int]`、抽数和保底 | save load | snapshot | 非法键/负数拒绝 |
| `SignalRecruitService` | 无长期状态 | count、S target、state | draw result | 锁定、券不足、目标非法不突变 |
| `ResearchBreakthroughService` | 免费十连 receipt | state | 10 个结果 | 已领取拒绝；结果由 command receipt 重放 |
| `FactoryService` | discovered/researched blueprint 与 research work | start/claim | 永久角色 | 重复领取不创建第二角色 |
| `LogisticsService` | 角色星级 | hero_id、waive flag | star event | 型号碎片不足不扣除 |
| `CommandExecutor` | 整个 GameState | durable envelope | persisted event | 保存失败回滚 clone |
| `LegionScreen` | 仅投影 | action signal | 可读状态 | 禁用操作并解释缺口 |
| `CampaignObjectiveProjection` | 无长期状态 | 当前完整 GameState | 研发/编队/实战/升星/Boss 单一目标 | 缺失阵营 receipt 时安全退回通用战役目标 |

Tier 1 阵营协议不增加新的存档字段：App Shell 仅在 `stage_2_5` 已首通时，从
`claim_faction_signal` durable receipt 重建阵营协议并注入第三章及以后关卡配置；
`BattleSession` 在首 tick 验证编队中至少有一名同阵营角色后，原子应用一次效果并发布
`faction_protocol`。表现层只消费事件，不决定协议是否生效。

Tier 2 沿用 command receipt，不增加 schema 字段：`stage_3_5` 首通只开放选择，玩家通过
`choose_faction_doctrine` durable command 在 `coordination` 与 `specialization` 中确定一次路线；
重复选择被领域拒绝。未选择时 `_active_faction_protocol()` 仍返回 Tier 1，选择后才从相同阵营
核心和 doctrine receipt 派生 Tier 2 并注入第四章。Tier 2 通过 `tier`、`allied_value`、
`zone_count` 与 `armor_break_bp` 表达覆盖/强度取舍；BattleSession 的事件和结算结果保留 tier，
CampaignObjectiveProjection 则在刷新后持续恢复待选目标，避免一次性结算弹窗成为唯一入口。

## 数据合同

`hero_fragments` 使用 `archetype_id → non-negative int`，只接受 FactoryCatalog 已知可招募型号。
存档升级时保留旧 `hero_shards` 供主动技能研究与历史兼容，不把它自动伪造为任何型号碎片。
旧重复图纸无法可靠推断来源，因此不迁移成专属碎片。

星级 quote 按角色 `aptitude_id` 选择需求，并按 `archetype_id` 查询余额。教学核心只将本次碎片成本
标记为 waived，不创建碎片。

S 级一星强度由 `HeroProgression.derived_battle_stats()` 的评级基础倍率提供；倍率是派生规则，不重复
写入 `HeroState.base_stats`，避免迁移和升级时二次乘算。

## UI 合同

- 玩家问题：这次抽到了谁，我的阵营可以向哪里发展？
- 两秒答案：结果卡明确显示“新图纸”或“某型号专属碎片 +N”；未选择时顶部并排显示两个候选的
  评级、阵营、真实现有搭档或待补战术、2★质变、碎片与48px选择动作，选择后才固定显示阵营核心
  和当前研发/培养状态。协同摘要由当前 `roster` 与 `FactionCatalog` 即时投影，不写入存档或战力。
- 主行动：有新图纸时为“前往研究所研发”；已有可升星角色时为“查看并升星”。
- 跨屏目标：领取后持续按“研发 → 编队 → 三场证明 → 2★ → 2-5”推进；目标中心与基地任务共享
  完全相同的小目标、CTA、stage_id 和 hero_id，后续普通招募不得覆盖阵营起手 receipt。
- 研发领取进入编队时，App Shell 选择首个空 `troop_*` 槽；`LegionScreen` 将 `journey_focus`
  候选只在展示层排到第一位，并把空槽名称、部署后人数与三场证明目标放在候选网格前。自动滚动对齐
  整个 `FormationCandidatePanel`，不只对齐按钮，且不替玩家提交编队命令。
- 次行动：单抽/十抽；查看保底与定向。
- 角色卡显示 `当前碎片/下一星需求` 和下一星质变文案。
- 844×390 下十连结果允许纵向滚动，按钮不小于 48 基准像素，不横向依赖溢出。

## 迁移与失败

- schema 从 v10 升为 v11，v10 自动增加空 `hero_fragments`。
- v5–v9 先走既有迁移，再进入 v11。
- 未知碎片键、负数或非整数存档拒绝，不能静默吞掉。
- 免费十连由 command business receipt 保留首次结果；刷新不得重抽。
- `choose_faction_core` 只接受该次免费十连回执中的两个候选，exact-once 保存玩家选择；非候选、
  第二次选择和选择后改选均拒绝。旧存档没有 `requires_core_choice` 时沿用原保证重复型号，避免迁移改阵营。
- 若 Web 持久化失败，CommandExecutor 返回失败且原状态不提交。

## 垂直里程碑

1. 专属碎片事务：抽取重复写型号碎片，升星只消费同型号；headless regression。
2. 阵营十连：免费十连稳定、至少 A、新型号和一次可升星重复；多 seed 扫描。
3. UI 与研发编队：结果、碎片、下一星质变、研究与编队可触达；844×390 smoke。
4. 第二章旅程：首章完成存档完成抽取、研究、上阵、升星和 2-1 至 2-5 验证。
5. Web 候选：全套回归、导出、artifact audit、Chrome 旅程；外部 URL 单独记录。

## 评审

`IMPLEMENTED_LOCAL`。产品方向、状态所有权与 UI 主路径均已实现，无需新增 Autoload 或第三方依赖。
招募结果从 durable command receipt 恢复；概率使用 32 位拒绝采样映射精确 basis points；
免费十连的第十响应也推进 A/S 保底，并在撞上 60 抽时同时保留保证重复与 S 保底结果。
持续游玩意愿、阵营认同和 S 级获得感仍需真人试玩，不能由 headless 结果证明。

Ready milestone: 免费阵营十连 → 新角色研发 → 专属碎片 2★ → 第二章出征
Confirmed inputs: 当前 GDD、用户确认方向、现有招募/研究/星级/BattleSession
Open decisions: 无阻塞决策；4★/5★与正式卡池运营延期
First validation: `godot --headless --path project-a --script res://tools/run_post_30m_faction_tests.gd`；
7 个 seed 均完成 1★前三关、后段成长墙、2★Lv2 通过 2-4、2★Lv3 通过 2-5；
`run_post_30m_ui_journey_tests.gd` 另从真实主场景点击十连、定向科技节点、研发领取、第三编队槽、
三场证明目标与精确角色升星，证明跨屏 CTA 没有退回泛化页面；同一测试锁定 844×390 下十连
奖励与新编队候选会自动进入视野，并验证科技、候选、名册和升星反馈持续指向同一阵营核心。
BattleSession 结果同时保留八类 2★机制的确定性计数，2-4/2-5 结算按 durable 十连核心与实际
部署名单生成“阵营质变验证”；领域旅程证明真实战斗能产生对应计数，UI 旅程与
`ui-faction-chapter-two-proof-844x390.png` 证明玩家能在小屏结算首屏看到角色、机制与次数。
StageCatalog 为第二章每关提供可检查的共振周期、预警、能量削减和虚弱时长；BattleSession 生成
`resonance_warning` / `resonance_pulse` 并在结果中累计次数和真实能量损失。BattleWorld 将这两类
低频章节事件连同紫色波纹送达 HUD，不再像普通 5Hz 攻击一样过滤；HUD 以炮击预警更高优先级展示
共振决策窗口，结算对 2-1–2-4 优先输出声波归因。
2-5 胜利不再直接启动 3-1：结果页生成章节完成与电视控制威胁预告，`map_stage` 从目标关卡配置
推导正确章号并打开第三章侦察页。CampaignObjectiveProjection 的通用章节文案已按第2–5章配置，
不再把 3-1 及以后错误标记为“第二章声波防线”。UI 旅程同时锁定 844×390 CTA 边界。
Residual risk: 真人阵营认同、移动端触控和生产 origin 持久化

---
km_id: reference.character-player-repair
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/content/faction_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot --project-root project-a
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:hero-formation
related:
  - reference.character-roster-index
---

# 研究员马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `repair` / `special.repair` |
| 评级/职业/阵营 | B / `guardian` / 钢铁防线 |
| 1★/2★/3★ CP | 1638 / 2049 / 2460 |
| 主动技能 | `field_repair` 战地抢修 |
| 工厂成本 | 瓷片18、零件20、污泥26；15秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 190 | 21 | 40 | 84000 | 8.00% | 1638 | 2049 | 2460 |
| 2 | 210 | 23 | 44 | 85600 | 8.20% | 1783 | 2222 | 2681 |
| 3 | 230 | 25 | 48 | 87200 | 8.40% | 1928 | 2415 | 2922 |
| 4 | 250 | 28 | 52 | 88800 | 8.60% | 2093 | 2628 | 3173 |
| 5 | 270 | 30 | 56 | 90400 | 8.80% | 2238 | 2821 | 3414 |

Lv5派生属性：1★`270/30/56`，2★`351/39/72`，3★`432/48/89`。射程34；移动8→8/tick；
攻击周期6→6 tick；基础技能循环约30 tick，受击回能可能提前。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片18、零件20、污泥26，15秒；材料价值242金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 20 + 40 = 60个`repair`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 60碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 抢修最低生命友军；2★扩为三名目标；3★优先拉起一名本局倒下
主力。详细治疗和复活选择以 `BattleSession._heal_lowest_allies()` 为准。

**定位：** 炮击后或主力将倒下时恢复战线。相比装甲是事后恢复而非预警格挡；相比寄生不分担
目标，但能稳定保护永久主力。

**表现/验证：** 工具臂、修复束、群修与首次拉起要区分。测试最低血排序、目标上限、仅本局复活、
战后全员100%可出征以及钢铁防线协议。

## 优化分析

- **当前效率：** Lv1→5增加600/772/954 CP；面板低于装甲，但B碎片成本少30。
- **同类对比：** 装甲预防爆发，维修修复已发生伤害；两者同队应互补而非形成无限循环。
- **目标预算：** 1★可靠救最低血，2★应在AOE后明显优于单修，3★每局首次拉起形成质变。
- **过强/过弱信号：** 治疗量长期超过团队实际受伤并消除失败为过强；按时施放仍无法改变任何一名
  主力生存结果为过弱。
- **首选杠杆：** 调治疗比例、目标数和拉起生命，不先加攻击/CP；代表Boss中团队有效生存时间提高
  20%–35%为目标，超过50%且无输出代价触发回滚。

**风险：** 治疗和复活不进入CP；不得引入跨局维修消耗。

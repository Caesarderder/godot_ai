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

# 维修马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `repair` / `special.repair` |
| 评级/职业/阵营 | B / `guardian` / 钢铁防线 |
| 1★/2★/3★ CP | 1638 / 2049 / 2460 |
| 主动技能 | `field_repair` 战地抢修 |
| 工厂成本 | 瓷片18、零件20、污泥26；15秒 |

**战斗合同（implemented）：** 抢修最低生命友军；2★扩为三名目标；3★优先拉起一名本局倒下
主力。详细治疗和复活选择以 `BattleSession._heal_lowest_allies()` 为准。

**定位：** 炮击后或主力将倒下时恢复战线。相比装甲是事后恢复而非预警格挡；相比寄生不分担
目标，但能稳定保护永久主力。

**表现/验证：** 工具臂、修复束、群修与首次拉起要区分。测试最低血排序、目标上限、仅本局复活、
战后全员100%可出征以及钢铁防线协议。

**风险：** 续航价值不进入CP；不得通过跨局维修消耗回收其价值。

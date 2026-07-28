---
km_id: reference.character-player-armored
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

# 装甲冲城马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `armored` / `heavy.armored` |
| 评级/职业/阵营 | A / `guardian` / 钢铁防线 |
| 1★/2★/3★ CP | 1638 / 2049 / 2460 |
| 主动技能 | `siege_shield` 攻城护盾 |
| 工厂成本 | 瓷片30、零件28、污泥12；12秒 |

**战斗合同（implemented）：** 全星为全体存活友军加35 tick护盾；比例为26%/40%/48%。2★同时
冲击装甲门或当前目标，并给全队300 tick巨炮格挡，炮击伤害减半且反震炮台；3★嘲讽精英25 tick。

**定位：** 巨炮预警内把承压转成反攻窗口。相比维修是预防伤害；相比Gman是团队防御而非清场。
1-4 的确定性研发链提供关键非随机解法。

**表现/验证：** 护盾、巨炮格挡、反震和嘲讽要有不同反馈。测试全队覆盖、炮击减伤、反震60伤害、
精英目标和移动堡垒协议。

**风险：** 不能让所有Boss只有装甲唯一解；火箭压炮与维修续航必须保持替代路径。

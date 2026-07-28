---
km_id: reference.character-player-rocket
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

# 火箭飞行马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `rocket` / `flying.rocket` |
| 评级/职业/阵营 | B / `ranger` / 远程轰炸 |
| 1★/2★/3★ CP | 1419 / 1736 / 2053 |
| 主动技能 | `rocket_salvo` 火箭齐射 |
| 工厂成本 | 瓷片10、零件24、污泥18；10秒 |

**战斗合同（implemented）：** 1★轰击当前目标；2★齐射当前阶段全部目标，并对结构使用更高
倍率；3★命中结构时施加30 tick破甲，默认使后续承伤提高25%。

**定位：** 在设施层或 Boss 外甲暴露时快速拆塔。相比自爆，持续攻城且无自损；相比双锯，覆盖
结构和多目标而非优先精英。远程轰炸协议进一步标定结构。

**表现/验证：** 飞行轮廓、弹道、范围爆炸和结构破甲必须可读。测试多目标、结构倍率、破甲计时、
关卡防空扫描停火但不伤害永久角色。

**风险：** 第四章反飞行要求存在地面替代，关键路径不得强制本角色。

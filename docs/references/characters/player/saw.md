---
km_id: reference.character-player-saw
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

# 双锯重装马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `saw` / `heavy.saw` |
| 评级/职业/阵营 | S / `fighter` / 快攻破城 |
| 1★/2★/3★ CP | 2294 / 2893 / 3502 |
| 主动技能 | `saw_rush` 双锯突袭 |
| 工厂成本 | 瓷片26、零件34、污泥14；14秒 |

**战斗合同（implemented）：** 优先选择当前精英，否则攻击当前目标；1★3倍攻击；2★先4倍再
追加2倍连斩；3★若击杀则返还55能量。

**定位：** 对高价值精英建立连续斩杀节奏。相比冲锋更昂贵、更单点且优先精英；相比火箭不擅长
范围拆塔。S级1★基础CP已高于同职业B/A 2★基准。

**表现/验证：** 双锯锁定、两段命中和击杀回能必须清楚。测试精英优先、无精英回退、连斩次数、
死亡判定与开局能量协议。

**风险：** 当前快照中没有 fallback 推荐；需避免高评级变成“有就碾压、无就卡关”。

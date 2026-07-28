---
km_id: reference.character-alliance-alliance-elite
km_type: reference
domain: battle-progression
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - project-a/tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:battle-progression
related:
  - reference.character-roster-index
---

# 联合核心近卫

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `alliance_elite` |
| 投放 | 第四、五章中段 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防12、射程38、攻击周期8 tick |

**战斗问题：** 高耐久中线精英保护联合模块和后排，检验阵容是否同时具备斩杀与续航。

**反馈与反制：** 三族重甲和核心徽记应清晰；双锯斩杀、火箭跨目标、装甲反炮为不同路径。

**边界：** 名称与共享 `core_guard` 相近但稳定ID不同；本角色在中段，`core_guard` 固定守核心前。

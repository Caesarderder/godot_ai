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

## 数值与预算

4-1为`541/82/34`，4-5为`636/97/40`，5-1为`665/101/42`，5-5为`760/116/48`；每波1名，
射程38、周期8 tick、移动4。无培养成本；模块护盾另加24–28点。

**战斗问题：** 高耐久中线精英保护联合模块和后排，检验阵容是否同时具备斩杀与续航。

**反馈与反制：** 三族重甲和核心徽记应清晰；双锯斩杀、火箭跨目标、装甲反炮为不同路径。

**优化规划：** 若护盾后有效HP使双锯相对普通输出不再有20%以上TTK优势，应降低护盾目标频率；
若未触发模块就被一次技能秒杀则提高HP。不要与全局倍率同步再加独立减伤。

**边界：** 名称与共享 `core_guard` 相近但稳定ID不同；本角色在中段，`core_guard` 固定守核心前。

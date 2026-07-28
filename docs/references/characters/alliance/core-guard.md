---
km_id: reference.character-alliance-core-guard
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

# 核心近卫

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `core_guard` |
| 投放 | 所有模板关的第三战斗带，左右各一 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防13、射程38、攻击周期7 tick |

**战斗问题：** 在核心前形成最后一对高频门卫，迫使玩家决定先清精英还是抢拆结构。

**反馈与反制：** 成对重甲剪影和核心近卫标识必须可读；双锯是精英软克制，音波/装甲/火箭提供
控制、承压和抢拆替代。

**边界：** `core_guard` 跨家族复用；不要为每章复制成新角色，家族差异由章节机制表达。

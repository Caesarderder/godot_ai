---
km_id: reference.character-alliance-tv-elite
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

# 电视监军

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `tv_elite` |
| 投放 | 第三章中段 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防12、射程38、攻击周期8 tick |

**战斗问题：** 作为高耐久精英承接传送与护盾主题，让玩家重新锁定并集中破盾。

**反馈与反制：** 青色传送残影、护盾和精英框必须分层显示；双锯、火箭和保留的一轮集中技能是
主解，持续集火仍可替代。

**边界：** TV护盾是关卡机制为高伤精英选择目标，并非 `tv_elite` 自施法。

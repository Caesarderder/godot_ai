---
km_id: reference.character-alliance-alliance-overseer
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

# 联合核心监军

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `alliance_overseer` |
| 投放 | 第四、五章第4关起的后线 |
| 职业/精英 | `arcanist` / 是 |
| 未缩放基准 | HP240、攻34、防11、射程96、攻击周期8 tick |

**战斗问题：** 作为高伤监军承载联合模块轮换的视觉焦点，要求玩家按当前模块保留不同反制。

**反馈与反制：** 红标、蓝色防空、净化脉冲和护盾必须显示真实目标；装甲/维修应对标记，地面
输出应对防空，错峰召唤应对净化，集中爆发应对护盾。

**边界：** 四模块由 `_run_alliance_mechanics()` 按关卡固定顺序执行，当前并非监军独占技能。

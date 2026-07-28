---
km_id: reference.character-alliance-tv-overseer
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

# 电视监军高阶型

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `tv_overseer` |
| 投放 | 第三章第4关起的后线 |
| 职业/精英 | `arcanist` / 是 |
| 未缩放基准 | HP240、攻34、防11、射程96、攻击周期8 tick |

**战斗问题：** 高伤后线精英与有限屏幕控制共同检验玩家是否把全部技能压在单一角色。

**反馈与反制：** 高阶屏幕图案、控制提示和远程攻击需分开；分散技能、装甲承压、维修与双锯斩杀
均为路径。

**边界：** 控制会选低生命关键成员，但由关卡级计数器触发，不是本单位独占施法。

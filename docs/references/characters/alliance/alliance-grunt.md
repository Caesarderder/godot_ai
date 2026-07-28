---
km_id: reference.character-alliance-alliance-grunt
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

# 联盟联合兵

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `alliance_grunt` |
| 投放 | 第四、五章基础双兵 |
| 职业/精英 | `fighter` / 否 |
| 未缩放基准 | HP95、攻18、防5、射程34、攻击周期8 tick |

**战斗问题：** 作为三族联合防线的基础占线单位，让标记、防空、净化和护盾模块有时间轮换。

**反馈与反制：** 混合三族零件但保持普通兵轮廓；地面清线、音波和装甲都是稳定解。

**边界：** 联合模块来自关卡配置；普通兵本身不同时拥有四种技能。

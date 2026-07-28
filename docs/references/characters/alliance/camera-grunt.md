---
km_id: reference.character-alliance-camera-grunt
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

# Camera 基础兵

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_grunt` |
| 投放 | 第一章模板，左右基础位 |
| 职业/精英 | `fighter` / 否 |
| 未缩放基准 | HP95、攻18、防5、射程34、攻击周期8 tick |

**战斗问题：** 近距双兵稳定占线，为摄像射手和盾卫争取输出时间；关卡按敌军战力倍率缩放。

**反馈与反制：** 步兵推进与短射程要区别于射手；冲锋顺劈是主解，音波/普通集火是替代。

**边界：** 第一章的标记射击是章节/关卡主题，不是该单位当前独占技能。

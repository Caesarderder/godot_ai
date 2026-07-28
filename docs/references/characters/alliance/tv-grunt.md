---
km_id: reference.character-alliance-tv-grunt
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

# 电视特工

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `tv_grunt` |
| 投放 | 第三章基础双兵 |
| 职业/精英 | `fighter` / 否 |
| 未缩放基准 | HP95、攻18、防5、射程34、攻击周期8 tick |

**战斗问题：** 基础占线为第三章信号消失、传送和屏幕控制创造观察窗口。

**反馈与反制：** 屏幕面部、青色信号和近距攻击要可区分；目标消失时转火其他敌人，冲锋/音波均为
低门槛替代。

**边界：** 信号消失由关卡级 `_run_tv_mechanics()` 选择目标，不保证来自本单位。

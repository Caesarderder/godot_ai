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

## 数值与预算

| 关卡 | 倍率 | 单体HP/攻/防 | 2名整组HP/攻 |
|---|---:|---|---|
| 3-1 | 202% | 191 / 36 / 10 | 382 / 72 |
| 3-5 | 270% | 256 / 48 / 13 | 512 / 96 |

射程34、周期8 tick、移动4；无培养成本。信号模块另计，不进入单兵属性。

**战斗问题：** 基础占线为第三章信号消失、传送和屏幕控制创造观察窗口。

**反馈与反制：** 屏幕面部、青色信号和近距攻击要可区分；目标消失时转火其他敌人，冲锋/音波均为
低门槛替代。

**优化规划：** 3-1同时引入信号消失，基础兵伤害应低于机制学习价值。若玩家在理解转火前被普通
攻击击倒则降攻；若信号消失不改变任何目标选择则延长机制时长而非加兵。

**边界：** 信号消失由关卡级 `_run_tv_mechanics()` 选择目标，不保证来自本单位。

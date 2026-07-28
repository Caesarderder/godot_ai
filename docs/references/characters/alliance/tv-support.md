---
km_id: reference.character-alliance-tv-support
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

# 电视特工射手

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `tv_support` |
| 投放 | 第三章远程位与侧翼 |
| 职业/精英 | `arcanist` / 否 |
| 未缩放基准 | HP95、攻20、防5、射程108、攻击周期8 tick |

## 数值与预算

3-1单体`191/40/10`，3-5单体`256/54/13`；Boss三名合计HP768、攻击162。数量按1→3递增，
射程108、周期8 tick、移动4。无培养成本。

**战斗问题：** 在信号干扰期间保持远程输出，惩罚玩家追逐暂时消失的原目标。

**反馈与反制：** 远程屏幕束和目标丢失反馈应分开；火箭跨目标、召唤分担、音波控制均可处理。

**优化规划：** Boss三射手攻击预算162是普通单位主要火力。若TV控制期间无法通过其他角色承压，
应错开控制与射击或减少一名侧翼；若转火不降低受伤则提高目标切换收益。

**边界：** 没有单位独占传送；第三章传送按关卡周期移动精英目标。

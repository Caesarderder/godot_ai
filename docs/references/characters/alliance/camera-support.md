---
km_id: reference.character-alliance-camera-support
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

# Camera 射手

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_support` |
| 投放 | 第一章，右后排；第二关起增加左翼，第三关起再加右翼 |
| 职业/精英 | `ranger` / 否 |
| 未缩放基准 | HP95、攻20、防5、射程108、攻击周期8 tick |

**战斗问题：** 用远射程侧翼迫使玩家关心前后排和清线速度，而不是只打中路精英。

**反馈与反制：** 长镜头/枪械和瞄准线应先于命中；冲锋清兵、音波降攻或火箭跨目标均可解。

**边界：** 没有已实现的单位级标记；第四章联合标记由关卡模块运行。

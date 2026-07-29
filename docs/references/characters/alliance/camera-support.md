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

## 数值与预算

第一章固定值；数量从1名递增到第3关起3名，Boss波整组HP285、攻击预算60；移动4/tick、
1.6秒攻击一次。无培养成本；额外内容成本来自侧翼站位和瞄准线。

**战斗问题：** 用远射程侧翼迫使玩家关心前后排和清线速度，而不是只打中路精英。

**反馈与反制：** 长镜头/枪械和瞄准线应先于命中；冲锋清兵、音波降攻或火箭跨目标均可解。

**优化规划：** 支援位的危险应主要来自数量递增。若第3名加入使团队承伤跳升超过前一关40%，先
延长周期而非减HP；若玩家无需调整前后排，增加侧翼读秒而非直接加攻。

**边界：** 没有已实现的单位级标记；第四章三色标记街由关卡模块运行。

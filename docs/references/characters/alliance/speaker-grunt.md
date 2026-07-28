---
km_id: reference.character-alliance-speaker-grunt
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

# 联盟音箱兵

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `speaker_grunt` |
| 投放 | 第二章基础双兵 |
| 职业/精英 | `fighter` / 否 |
| 未缩放基准 | HP95、攻18、防5、射程34、攻击周期8 tick |

**战斗问题：** 近距占线配合第二章声波/能量干扰主题，迫使玩家提前规划技能窗口。

**反馈与反制：** 音箱振膜与近距脉冲要区别于Camera枪击；音波、自爆和维修是章节推荐，冲锋仍是
基础清线替代。

**边界：** 当前声波干扰由关卡配置驱动，不是该兵独占技能。

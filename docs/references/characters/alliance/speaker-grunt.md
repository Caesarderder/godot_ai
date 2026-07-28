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

## 数值与预算

| 关卡 | 倍率 | 单体HP/攻/防 | 2名整组HP/攻 |
|---|---:|---|---|
| 2-1 | 112% | 106 / 20 / 5 | 212 / 40 |
| 2-5 | 180% | 171 / 32 / 9 | 342 / 64 |

射程34、周期8 tick、移动4/tick不缩放；Boss波固定2名。无培养成本。

**战斗问题：** 近距占线配合第二章声波/能量干扰主题，迫使玩家提前规划技能窗口。

**反馈与反制：** 音箱振膜与近距脉冲要区别于Camera枪击；音波、自爆和维修是章节推荐，冲锋仍是
基础清线替代。

**优化规划：** 单兵只负责占线，能量削减属于关卡预算。若2-5基础兵造成的团队伤害超过共振脉冲，
应先降攻或延长周期；若无法拖住后排一轮攻击则提高HP。禁止同时提高倍率和共振伤害。

**边界：** 当前声波干扰由关卡配置驱动，不是该兵独占技能。

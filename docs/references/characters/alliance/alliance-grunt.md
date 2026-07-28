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

## 数值与预算

| 关卡 | 倍率 | 单体HP/攻/防 | 2名整组HP/攻 |
|---|---:|---|---|
| 4-1 | 285% | 270 / 51 / 14 | 540 / 102 |
| 4-5 | 335% | 318 / 60 / 16 | 636 / 120 |
| 5-1 | 350% | 332 / 63 / 17 | 664 / 126 |
| 5-5 | 400% | 380 / 72 / 20 | 760 / 144 |

射程34、周期8 tick、移动4；无培养成本。联合模块单独计入关卡预算。

**战斗问题：** 作为三族联合防线的基础占线单位，让标记、防空、净化和护盾模块有时间轮换。

**反馈与反制：** 混合三族零件但保持普通兵轮廓；地面清线、音波和装甲都是稳定解。

**优化规划：** 基础兵不能与模块同时成为主要失败源。若4-1标记目标未出现前两兵已造成超过团队
20%最大生命伤害，应降攻；若完全拖不住第一轮阵营技能则提高HP而非模块强度。

**边界：** 联合模块来自关卡配置；普通兵本身不同时拥有四种技能。

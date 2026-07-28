---
km_id: reference.character-alliance-camera-elite
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

# 摄像盾卫

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_elite` |
| 投放 | 第一章中段 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防12、射程38、攻击周期8 tick |

**战斗问题：** 在中段卡住低爆发阵容，让后排摄像射手获得额外输出时间。

**反馈与反制：** 大盾、精英外框和受击反馈必须明显；双锯优先斩杀，火箭/冲锋为可用替代。

**边界：** “盾卫”当前只由高HP/防御表达，没有独立护盾状态。

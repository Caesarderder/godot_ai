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

## 数值与预算

第一章固定1名：HP190、攻击29、防12；移动4/tick、1.6秒攻击一次。其HP等于两名基础兵总和，
攻击低于两兵合计36，承担“延长窗口”而非爆发。无培养成本；需精英模型/盾牌反馈。

**战斗问题：** 在中段卡住低爆发阵容，让后排摄像射手获得额外输出时间。

**反馈与反制：** 大盾、精英外框和受击反馈必须明显；双锯优先斩杀，火箭/冲锋为可用替代。

**优化规划：** 双锯对其TTK应比冲锋短20%–35%（target）；若普通清线技能同样秒杀则精英身份
过弱，若无双锯时存活超过整波其余单位则过强。优先调防12。

**边界：** “盾卫”当前只由高HP/防御表达，没有独立护盾状态。

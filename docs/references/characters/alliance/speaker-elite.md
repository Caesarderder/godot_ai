---
km_id: reference.character-alliance-speaker-elite
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

# 大型音箱兵

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `speaker_elite` |
| 投放 | 第二章中段 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防12、射程38、攻击周期8 tick |

**战斗问题：** 大体型精英延长声波压力，使爆发与续航同样重要。

**反馈与反制：** 大型音箱、低频冲击和精英标记必须清楚；双锯快速斩杀，装甲/维修稳定拖过，
自爆提供爆发替代。

**边界：** 当前没有单位级击退；若未来加入必须同步行为、表现与固定seed测试。

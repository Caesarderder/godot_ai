---
km_id: reference.character-alliance-speaker-overseer
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

# 大型音箱监军

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `speaker_overseer` |
| 投放 | 第二章第4关起的后线 |
| 职业/精英 | `arcanist` / 是 |
| 未缩放基准 | HP240、攻34、防11、射程96、攻击周期8 tick |

**战斗问题：** 在后线维持高伤压力，承载第二章“技能节奏被打乱”的监军视觉主题。

**反馈与反制：** 指挥音轨与高功率脉冲必须先于攻击；双锯优先精英、火箭跨目标、维修续航均可解。

**边界：** 当前没有监军独占能量干扰逻辑；不可把章节文案当作单位技能事实。

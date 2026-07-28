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

## 数值与预算

首次出现的2-4（160%）为`384/54/17`，2-5为`432/61/19`；射程96、周期8 tick、移动4。
每波1名。无培养成本；监军机制若新增必须另计模块预算。

**战斗问题：** 在后线维持高伤压力，承载第二章“技能节奏被打乱”的监军视觉主题。

**反馈与反制：** 指挥音轨与高功率脉冲必须先于攻击；双锯优先精英、火箭跨目标、维修续航均可解。

**优化规划：** 2-5攻击61与共振18能量削减共同施压。若玩家失败归因无法区分监军伤害和共振，
先降低攻击或错开周期；若监军通常在首次攻击前死亡则增加HP而不是隐藏机制。

**边界：** 当前没有监军独占能量干扰逻辑；不可把章节文案当作单位技能事实。

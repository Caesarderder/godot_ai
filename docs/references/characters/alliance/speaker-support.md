---
km_id: reference.character-alliance-speaker-support
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

# 音箱射手

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `speaker_support` |
| 投放 | 第二章远程位与递增侧翼 |
| 职业/精英 | `arcanist` / 否 |
| 未缩放基准 | HP95、攻20、防5、射程108、攻击周期8 tick |

## 数值与预算

| 关卡 | 倍率 | 单体HP/攻/防 | Boss 3名HP/攻 |
|---|---:|---|---|
| 2-1 | 112% | 106 / 22 / 5 | — |
| 2-5 | 180% | 171 / 36 / 9 | 513 / 108 |

数量按1→2→3递增；射程108、周期8 tick、移动4/tick。无培养成本。

**战斗问题：** 在近战音箱兵身后维持远程节奏压力，惩罚只堆前排伤害的阵容。

**反馈与反制：** 定向声波束要有预备动作；火箭跨目标、自爆波及、音波削弱和装甲承压都能处理。

**优化规划：** 2-5三名射手的攻击预算108已高于两名基础兵64。若远程位贡献超过整波普通伤害
65%，先减数量而非削弱单体辨识；若无前后排差异则增强预警/站位，不直接加攻。

**边界：** “射手”只表示射程/职业模板，未实现独立沉默或能量抽取。

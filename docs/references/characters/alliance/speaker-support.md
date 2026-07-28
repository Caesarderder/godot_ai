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

**战斗问题：** 在近战音箱兵身后维持远程节奏压力，惩罚只堆前排伤害的阵容。

**反馈与反制：** 定向声波束要有预备动作；火箭跨目标、自爆波及、音波削弱和装甲承压都能处理。

**边界：** “射手”只表示射程/职业模板，未实现独立沉默或能量抽取。

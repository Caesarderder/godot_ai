---
km_id: reference.character-alliance-core-guard
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

# 核心近卫

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `core_guard` |
| 投放 | 所有模板关的第三战斗带，左右各一 |
| 职业/精英 | `guardian` / 是 |
| 未缩放基准 | HP190、攻29、防13、射程38、攻击周期7 tick |

## 数值与预算

| 代表关卡 | 倍率 | 单体HP/攻/防 | 2名整组HP/攻 |
|---|---:|---|---|
| 第一章 | 固定 | 190 / 29 / 13 | 380 / 58 |
| 2-5 | 180% | 342 / 52 / 23 | 684 / 104 |
| 3-5 | 270% | 513 / 78 / 35 | 1026 / 156 |
| 4-5 | 335% | 636 / 97 / 43 | 1272 / 194 |
| 5-5 | 400% | 760 / 116 / 52 | 1520 / 232 |

射程38、周期7 tick（1.4秒）、移动4/tick不缩放。无培养成本；跨章复用模型降低内容成本。

**战斗问题：** 在核心前形成最后一对高频门卫，迫使玩家决定先清精英还是抢拆结构。

**反馈与反制：** 成对重甲剪影和核心近卫标识必须可读；双锯是精英软克制，音波/装甲/火箭提供
控制、承压和抢拆替代。

**优化规划：** 两名近卫与核心炮叠加时是主要风险。若近卫整组HP超过同关核心外甲预算的50%需
复核；若火箭可完全忽略近卫且无生存代价则偏弱。优先调数量2或周期7，避免与全局倍率同时上调。

**边界：** `core_guard` 跨家族复用；不要为每章复制成新角色，家族差异由章节机制表达。

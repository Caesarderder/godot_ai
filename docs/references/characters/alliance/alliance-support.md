---
km_id: reference.character-alliance-alliance-support
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

# 联盟联合射手

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `alliance_support` |
| 投放 | 第四、五章远程位与侧翼 |
| 职业/精英 | `guardian` / 否 |
| 未缩放基准 | HP95、攻20、防5、射程108、攻击周期8 tick |

## 数值与预算

| 关卡 | 单体HP/攻/防 | Boss 3名HP/攻 |
|---|---|---|
| 4-1 | 270 / 57 / 14 | — |
| 4-5 | 318 / 67 / 16 | 954 / 201 |
| 5-1 | 332 / 70 / 17 | — |
| 5-5 | 380 / 80 / 20 | 1140 / 240 |

数量从1递增到3；射程108、周期8 tick、移动4。无培养成本。

**战斗问题：** 在联合模块切换时维持远程压力，迫使玩家保留地面输出而非纯飞行编队。

**反馈与反制：** 联合枪械、长射程瞄准和模块提示必须分层；音波、装甲、维修和地面快攻可解。

**优化规划：** 5-5三射手攻击预算240高于两基础兵144。若防空让飞行位停火时射手又能无窗口
集火，先错开防空与射击或减数量；若混编地面阵容仍无压力，调整站位而非继续倍率膨胀。

**边界：** 模板把联合远程职业设为 `guardian`；这是当前代码事实，是否改为 `ranger` 需另行评审。

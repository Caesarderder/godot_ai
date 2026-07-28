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

**战斗问题：** 在联合模块切换时维持远程压力，迫使玩家保留地面输出而非纯飞行编队。

**反馈与反制：** 联合枪械、长射程瞄准和模块提示必须分层；音波、装甲、维修和地面快攻可解。

**边界：** 模板把联合远程职业设为 `guardian`；这是当前代码事实，是否改为 `ranger` 需另行评审。

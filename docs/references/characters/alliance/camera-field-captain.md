---
km_id: reference.character-alliance-camera-field-captain
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

# 联盟临时队长

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_field_captain` |
| 首次出现 | 1-3 市政厅路障 |
| 职业/精英 | `guardian` / 是 |
| 基础模板 | HP147、攻19、防7、射程110、攻击周期9 tick |

## 数值与预算

1-3固定1名：总HP147、攻击预算19；移动4/tick、1.8秒攻击一次。与同关3名摄像兵合计敌军
HP411、攻击预算67。无培养成本；新增表现复杂度为精英轮廓与锁定标识。

**战斗问题：** 首次用高耐久中线精英延长交叉火力窗口，教玩家识别精英而非只清普通兵。

**反馈与反制：** 更大盾牌/队长轮廓与精英标识必须明显；Gman仍可处理，后续双锯是最清晰软克制，
冲锋与火箭保留替代。

**优化规划：** 队长应是1-3最后倒下的角色但不能单独形成墙。若其存活时间超过三名摄像兵总和的
50%则先降HP；若与普通兵同时死亡则提高HP或防御。不要凭名称加入未预算光环。

**边界：** 当前没有队长光环；不可把“队长”名称写成未实现增益。

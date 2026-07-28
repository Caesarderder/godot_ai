---
km_id: reference.character-player-gman
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/recruitment/hero_generator.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/resources/definitions/skills/active/gman_overrun.tres
validated_by:
  - project-a/tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:hero-formation
related:
  - reference.character-roster-index
---

# Gman 指挥官

| 字段 | 当前事实 |
|---|---|
| 稳定 ID | `gman` |
| 获取/评级 | 开局唯一永久角色；B |
| 职业/阵营 | `guardian`；钢铁防线 |
| 职责 | 全线攻坚、开局教学、短时自保 |
| 主动技能 | `gman_overrun` 统帅碾压 |
| 科技树 | 阵营成员，但不是工厂配方节点 |

**战斗合同（implemented）：** 技能伤害当前阶段全部敌人与结构并获得 80 点、20 tick 护盾；首次
施放可读取关卡开场倍率，后续回到基础倍率。前三关承担单人教学，1-4 之后让位给编队与成长。

**玩家承诺：** 防线集中出现时，用全线碾压一次打开推进窗口。与火箭的区别是覆盖敌人与结构且
兼具护盾；与装甲的区别是主攻而非长期承炮。

**表现与验证：** 巨型指挥官轮廓、整段冲击和护盾必须同时可读。验证首发强化只触发一次、阶段
目标覆盖、护盾持续时间、1-1 至 1-3 单人链，以及 844×390 技能说明。

**风险/未知：** 快照工具当前不把 Gman 纳入八名可招募角色 CP 表；不得据此误判其不存在。

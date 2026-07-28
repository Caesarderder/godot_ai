---
km_id: reference.character-alliance-camera-trooper
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

# 联盟摄像兵

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_trooper` |
| 首次出现 | 1-3 联盟集结 |
| 职业/精英 | `ranger` / 否 |
| 基础模板 | HP88、攻16、防3、射程120、攻击周期9 tick |

## 数值与预算

1-3固定生成3名：整组HP264、攻击预算48；移动4/tick，约1.8秒攻击一次。数值不套
`enemy_power_bp`。无培养成本；比1-2警卫单体HP+35%、攻击+45%，射程缩短25%。

**战斗问题：** 三路交叉火力把零散城市警卫升级成正式联盟编队，让玩家预览1-4炮墙的危险。

**反馈与反制：** 三个摄像头的同步瞄准应可读；Gman阶段清场是主解，后续冲锋清线、音波削弱均
为替代。

**优化规划：** 目标是让1-3比1-2明显掉血但仍可单人突破。若三兵在Gman一次全线技能后全部存活
且导致连续两轮技能才过关则偏强；若首次技能前无生命压力则偏弱。优先调HP88。

**边界：** 与后续 `camera_grunt` 是代码中的不同原型；不得因同名主题合并文档。

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

**战斗问题：** 三路交叉火力把零散城市警卫升级成正式联盟编队，让玩家预览1-4炮墙的危险。

**反馈与反制：** 三个摄像头的同步瞄准应可读；Gman阶段清场是主解，后续冲锋清线、音波削弱均
为替代。

**边界：** 与后续 `camera_grunt` 是代码中的不同原型；不得因同名主题合并文档。

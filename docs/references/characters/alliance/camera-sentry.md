---
km_id: reference.character-alliance-camera-sentry
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

# 远程摄像警卫

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_sentry` |
| 首次出现 | 1-2 城市警报 |
| 职业/精英 | `ranger` / 否 |
| 基础模板 | HP65、攻11、防2、射程160、攻击周期9 tick |

**战斗问题（implemented）：** 两名警卫从左右路首次告诉玩家“城市会远程还击”，但仍允许 Gman
单人突破。其职责是安全教学，不承担硬克制。

**反馈与反制：** 镜头瞄准和远程射线应先于命中；Gman全线技能是主解，持续推进是零门槛替代。

**边界：** 运行时 archetype 被统一为 `alliance`；当前没有单位独占标记技能。

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
| 首次出现 | 1-2 响铃商业街 |
| 职业/精英 | `ranger` / 否 |
| 基础模板 | HP65、攻11、防2、射程160、攻击周期9 tick |

## 数值与预算

1-2固定生成2名且不应用章节倍率：整组HP130、攻击预算22；移动4/tick，约1.8秒攻击一次。
无培养成本；内容成本仅为一个基础远程模型、瞄准提示和射击反馈。

**战斗问题（implemented）：** 两名警卫从左右路首次告诉玩家“城市会远程还击”，但仍允许 Gman
单人突破。其职责是安全教学，不承担硬克制。

**反馈与反制：** 镜头瞄准和远程射线应先于命中；Gman全线技能是主解，持续推进是零门槛替代。

**优化规划：** 目标是让Gman承受可见但不致命的第一轮远程伤害。若两名警卫在首次技能就绪前
击倒Gman则过强；若从未造成有效生命伤害则教学过弱。首选调攻击11或数量，不同时改射程与周期。

**边界：** 运行时 archetype 被统一为 `alliance`；当前没有单位独占标记技能。

---
km_id: domain.hero-formation
km_type: domain
domain: hero-formation
status: active
owner: gameplay
last_verified: 2026-07-24
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/game/scripts/state/hero_state.gd
  - project-a/game/scripts/state/formation_state.gd
  - project-a/game/scripts/domain/recruitment/hero_generator.gd
  - project-a/game/scripts/domain/progression/hero_progression.gd
  - project-a/game/scripts/domain/formation/formation_service.gd
  - project-a/tools/run_meta_tests.gd
validated_by:
  - godot --headless --path project-a -s tools/run_meta_tests.gd
tags:
  - domain:hero-formation
  - decision:p0-system
related:
  - domain.factory-cultivation
  - domain.product
  - domain.battle-progression
  - reference.first-30m-contract
---

# 英雄与编队领域

## 目标

让玩家看懂每个马桶人实例的职业、原型、星级和成长差异，通过训练、升星、换人和换位形成自己的六人主力。

## 什么时候读

设计英雄实例、职业/原型/资质/特质、等级成长、星级派生、队伍槽位或战斗快照时。

## 职责

- 英雄是唯一运行实例；当前职业、原型、资质、特质、姓名与成长规则由纯 GDScript 定义，静态 `.tres` 内容目录尚未建立。
- 实例已包含稳定 ID、姓名、职业、`archetype_id`、`star`、等级、经验、资质、特质、技能 ID 和装备槽引用；完整装备玩法尚未实现。
- 首版已实现四项属性 VIG/STR/AGI/INT、L1-L5、累计 XP 320 clamp、经验书消费与派生属性。
- 六槽已固定为 `front_left`、`front_center`、`front_right`、`back_left`、`back_center`、`back_right`，并校验英雄存在且不重复。
- 新档初始 8 个英雄，前 6 个上阵，后 2 个作为替换/培育空间；初始池包含 3 个装甲冲城马桶人用于验证 3 合 1。
- 战斗快照使用六人槽位、职业、原型、星级、派生生命/攻击/防御和技能 ID。

## 不是本层职责

不持有任务奖励、全局经济、存档写入或 UI 页面状态。

## 不变量

默认 UI/排序/AI/掉落/任务/胜负不得依赖 `debug_power`；英雄差异不能压缩成单一综合评分。

## 入口

当前实现入口见 [CODE:hero-generator](../../project-a/game/scripts/domain/recruitment/hero_generator.gd)、[CODE:hero-progression](../../project-a/game/scripts/domain/progression/hero_progression.gd)、[CODE:formation-service](../../project-a/game/scripts/domain/formation/formation_service.gd)、[CODE:formation-state](../../project-a/game/scripts/state/formation_state.gd) 和 [KM:reference.file-ownership](../references/indexes/file-ownership.md)。

## 验证

已通过 `tools/run_meta_tests.gd` 验证新档 8 英雄、固定 seed、连续招募增长、L1-L5 成长/clamp、严格六槽、重复/悬挂英雄 ID 拒绝、3 合 1 后编队引用迁移和英雄 ID 不复用。真人可读性观察尚未完成。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

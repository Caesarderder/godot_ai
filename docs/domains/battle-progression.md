---
km_id: domain.battle-progression
km_type: domain
domain: battle-progression
status: draft
owner: gameplay
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - plan-review-only
tags:
  - domain:battle-progression
  - risk:determinism
related:
  - domain.hero-formation
  - reference.architecture-overview
  - reference.verification-matrix
---

# 战斗与关卡推进领域

> 当前是批准设计，目标工程已存在但 `project-a/game/**` 战斗尚未实现，因此状态为 `draft`。

## 目标

用低频、可复现的自动战斗承载“先失败 -> 理解差异 -> 调整 -> 再胜”。

## 什么时候读

实现战斗状态、目标选择、技能、关卡、战斗回放、平衡模拟或结算时。

## 职责

- 5Hz 固定逻辑 tick；画面是战斗状态的投影，可丢动画，不丢逻辑 tick。
- 战斗使用局部 RNG、稳定 seed、定点行动条和稳定 tie-break。
- `BattleSession/BattleState` 是临时状态；只有不可变 `BattleResult` 可进入持久结算。
- 5 个关卡、每关 3 波；1-3 和 1-5 负责主要失败后成长再胜验证。

## 不是本层职责

不直接写 GameState、不发任务奖励、不持有 Node 作为持久真值。

## 不变量

相同 seed、内容和状态必须跨帧率得到相同 digest；全局随机函数禁止进入领域战斗。

## 入口

[KM:reference.architecture-overview](../references/architecture/architecture-overview.md)。

## 验证

hash/tie-break golden、30/60/120 FPS digest、同一 manifest 的 paired 1000 与绝对胜率区间。

## 相关节点

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

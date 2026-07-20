---
km_id: domain.battle-progression
km_type: domain
domain: battle-progression
status: draft
owner: gameplay
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - taptap/scripts/config/GameConfig.lua
  - taptap/scripts/game/GameState.lua
validated_by:
  - code-review
  - maker_build_current_directory
tags:
  - domain:battle-progression
  - risk:determinism
related:
  - domain.hero-formation
  - reference.architecture-overview
  - reference.verification-matrix
---

# 战斗与关卡推进领域

> TapTap 原型已有 30 关、0.25 秒攻击 tick、普通/精英/首领和自动结算；稳定 seed、独立 BattleSession、跨帧率 digest 与 paired 1000 门禁仍未落地，因此状态为 `draft`。

## 目标

用低频、可复现的自动战斗承载“先失败 -> 理解差异 -> 调整 -> 再胜”。

## 什么时候读

实现战斗状态、目标选择、技能、关卡、战斗回放、平衡模拟或结算时。

## 职责

- 5Hz 固定逻辑 tick；画面是战斗状态的投影，可丢动画，不丢逻辑 tick。
- 战斗使用局部 RNG、稳定 seed、定点行动条和稳定 tie-break。
- `BattleSession/BattleState` 是临时状态；只有不可变 `BattleResult` 可进入持久结算。
- 当前原型有 30 关；首版验收仍聚焦 1-1 到 1-5，其中 1-3 和 1-5 负责失败后成长再胜验证。

## 不是本层职责

不绕过 GameState 写持久值、不发任务奖励、不持有 UI Widget 作为持久真值。

## 不变量

相同 seed、内容和状态必须跨帧率得到相同 digest；全局随机函数禁止进入领域战斗。

## 入口

[KM:reference.architecture-overview](../references/architecture/architecture-overview.md)。

## 验证

当前 Maker 远端构建已通过；后续补 hash/tie-break golden、30/60/120 FPS digest、同一 manifest 的 paired 1000 与绝对胜率区间。

## 相关节点

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

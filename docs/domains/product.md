---
km_id: domain.product
km_type: domain
domain: product
status: active
owner: product-design
last_verified: 2026-07-17
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - deep-interview
  - ralplan-consensus
tags:
  - domain:product
  - decision:core-loop
related:
  - domain.hero-formation
  - domain.equipment-economy
  - domain.camp-quests
  - reference.product-boundaries
---

# 产品领域

## 目标

做一款手机端单机休闲放置游戏，让玩家通过随机英雄培养、队伍编成和挂机刷宝，获得开罗式目标感、正反馈和“这支队伍是我养出来的”体验。

## 什么时候读

改变玩法循环、系统深度、首局节奏、内容范围、商业化或平台前。

## 职责

- 核心循环：出征 -> 自动战斗/挂机产出 -> 任务提示 -> 招募/培养 -> 编队 -> 装备 -> 薄营地 -> 跨过卡点。
- 系统优先级：英雄/编队 P0，装备 P1，营地 P2，任务是横向软引导。
- 30 分钟目标：8 名英雄、理解 2 个差异维度、2 次主动编队调整、1 件稀有装备、一次失败后成长再胜。
- 首版内容预算：4 职业、4 资质、8 特质、4 槽、5 关、3 设施、5 大+16 小任务。

## 不是本层职责

不决定具体 GDScript 类、场景树、存档算法或 UI 节点结构。

## 不变量

任务不得硬锁后续关卡；随机英雄不得退化为固定卡；装备不得取代英雄本身；营地不得膨胀为复杂经营。

## 入口

[KM:reference.product-boundaries](../references/constraints/product-boundaries.md)、[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

## 验证

对照 5 人预注册观察：关键项至少 4/5，总 checkpoint 至少 45/50。

## 相关节点

[KM:invariant.project-boundaries](../map/invariants.md)。

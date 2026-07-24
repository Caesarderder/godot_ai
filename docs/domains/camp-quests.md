---
km_id: domain.camp-quests
km_type: domain
domain: camp-quests
status: draft
owner: gameplay
last_verified: 2026-07-24
source_of_truth:
  - docs/references/constraints/product-boundaries.md
validated_by:
  - user-correction-review-2026-07-24
tags:
  - domain:camp-quests
  - decision:p2-system
  - decision:soft-guidance
related:
  - domain.product
  - domain.equipment-economy
  - reference.product-boundaries
---

# 营地与任务领域

## 目标

记录 P2 候选营地与任务包装。当前基地首页只负责通往工厂、培育、编队和出征，不以旧酒馆/铁匠/训练场设施抢占 P0。

## 什么时候读

设计设施、任务、领域事件、任务进度、奖励或内容解锁时。

## 职责

- 当前 P0 只提供工厂、培育、编队和出征四个入口，以及不阻塞操作的教学提示。
- 酒馆、铁匠、训练场、设施升级、大任务和小任务均为 P2 候选，实施前重新确认其是否强化工厂攻城主题。
- 若实现任务，必须通过统一 DomainEvent/QuestReducer 推进，不轮询、不散落业务硬编码。
- 任务只提供软引导和反馈；跳过任务仍可生产、培育和出征。

## 不是本层职责

不定义工厂车间、生产队列、蓝图或英雄训练；这些属于当前 P0 的独立领域。也不做自由建造、人口模拟或关卡硬锁。

## 不变量

若实现设施升级和任务领奖，它们属于耐久价值操作；重复事件或命令不得重复进度/奖励。P2 系统不得成为 P0 失败后成长再胜的必要条件。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

当前仅验证 P0 不依赖任务或旧三设施。进入 P2 后再验证跳过任务仍能进关、重放、claim once 与设施 source/sink。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

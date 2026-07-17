---
km_id: domain.camp-quests
km_type: domain
domain: camp-quests
status: active
owner: gameplay
last_verified: 2026-07-17
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
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

用最薄营地包装长期成长，用大小任务提供方向和正反馈，同时保持玩家自由推进。

## 什么时候读

设计设施、任务、领域事件、任务进度、奖励或内容解锁时。

## 职责

- 酒馆、铁匠、训练场三设施，各 3 级、线性升级、直接服务核心循环。
- 5 个大任务提供阶段目标，16 个小任务提示当前可执行动作。
- 任务通过统一 DomainEvent/QuestReducer 推进，不轮询、不散落业务硬编码。
- 任务完成提供奖励和反馈，但跳过任务仍可进入后续关卡。

## 不是本层职责

不做自由建造、人口模拟、复杂生产链或关卡硬锁。

## 不变量

设施升级和任务领奖属于耐久价值操作；重复事件或命令不得重复进度/奖励。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

跳过任务仍能进关、600 条重放、claim once、设施 source/sink。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

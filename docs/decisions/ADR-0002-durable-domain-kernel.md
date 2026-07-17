---
km_id: decision.durable-domain-kernel
km_type: decision
domain: architecture
status: active
owner: architecture
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - architect-approve
  - critic-approve
tags:
  - decision:durable-domain-kernel
  - risk:state-consistency
related:
  - reference.architecture-overview
  - reference.state-command-lifecycle
  - invariant.project-boundaries
---

# ADR-0002：耐久领域内核

## 状态

Accepted as implementation plan；源码尚未落地。

## 决策

采用小型领域内核 + 薄 Godot 外壳：内核拥有 GameState、命令、战斗、任务、离线和持久化语义；Node/Control 只负责生命周期与表现。按 vertical slice 交付。

## 驱动因素

- 先验证英雄/编队 P0 乐趣。
- 移动杀进程下价值、时间、随机结果不重复且可恢复。
- 固定 seed、跨帧率和 headless 可复现。

## 备选

- Node-first：原型快，但持久状态、重放和场景切换边界弱；仅用于表现。
- ECS：扩展多队好，但当前 4vN 过度建设；多队成为已证需求后重评。
- Horizontal systems：便于专家分工，但集成与产品验证太晚；仅允许同一 slice 内并行。

## 后果

增加 command/DTO 样板和测试成本，换取状态所有权、崩溃语义和可验证性。禁止引入 DI 框架、ECS、数据库和自定义编辑器插件。

## 相关节点

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

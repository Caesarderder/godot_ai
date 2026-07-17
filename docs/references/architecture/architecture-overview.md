---
km_id: reference.architecture-overview
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - architect-plan-approval
tags:
  - reference:architecture-overview
  - risk:planned-not-implemented
related:
  - decision.durable-domain-kernel
  - reference.state-command-lifecycle
  - reference.file-ownership
---

# 架构总览

> 架构已经规划批准，但 `game/` 尚不存在；本节点在实现和测试落地前保持 `draft`。

## 目标

用小型领域内核承载状态、战斗、任务、离线和持久化语义，用 Godot Node/Control 负责生命周期与表现。

## 事实

- 选择 A1+B1：领域内核 + 薄 Godot 外壳，按 vertical slice milestone 交付。
- Node/场景可作为表现层，不得成为持久状态真值。
- 不引入 DI 框架、ECS、数据库或自定义编辑器框架。
- 计划中的 Autoload 顺序：SystemClock -> SaveManager -> ContentCatalog -> EventBus -> Game -> AppLifecycle。
- 持久 `GameState` 与临时 `BattleSession/BattleState` 分离；只有 `BattleResult` 进入结算。
- 领域逻辑必须能 headless 运行；UI 通过 presenter/controller 投影状态。

## 入口或路径

规划目录见 [KM:reference.file-ownership](../indexes/file-ownership.md)。路径存在性必须在 M0-M5 分阶段回填。

## 验证

M0 headless shell/Autoload，M1 state/save/commands，M2 heroes，M3 battle，M4 meta，M5 Android；全部完成后把本节点转为 `active`。

## 相关节点

[KM:decision.durable-domain-kernel](../../decisions/ADR-0002-durable-domain-kernel.md)。

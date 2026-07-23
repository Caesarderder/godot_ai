---
km_id: reference.architecture-overview
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-21
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/game
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - historical M0 headless and GUT verification
tags:
  - reference:architecture-overview
  - risk:planned-not-implemented
related:
  - decision.durable-domain-kernel
  - decision.godot-game-root-restored
  - reference.state-command-lifecycle
  - reference.file-ownership
---

# 架构总览

> 当前实现根已恢复为 `project-a/` Godot 工程。M1-M5 均按 Godot/GDScript/GUT 路线推进；节点保持 `draft`，直到各里程碑实现与验证证据完成回填。

## 目标

用 GDScript 领域内核承载状态、战斗、任务、离线和持久化语义，用 Godot Autoload、Node 与 Control 负责生命周期和纯 2D 表现。

## 事实

- 继续采用领域内核 + 薄 Godot 外壳，按 vertical slice milestone 交付；领域对象保持可序列化、可 headless 验证。
- UI Widget 与表现组件不得成为持久状态真值。
- 不引入 DI 框架、ECS、数据库或自定义编辑器框架。
- `project-a/game/scripts/autoloads/**` 负责生命周期与组合根；持久 `GameState` 和 `CommandExecutor` 承担状态事实与唯一写边界。
- 存档使用 `user://save_v1.json` 及候选写入/备份恢复协议；具体完成状态以 M1 测试证据为准。
- 持久 `GameState` 与临时 `BattleSession/BattleState` 分离；只有 `BattleResult` 进入结算。
- 领域逻辑必须可在无 UI 的 GUT/headless 测试与模拟中运行；UI 只投影领域状态。

## 入口或路径

当前入口为 `project-a/project.godot`、`project-a/game/**`、`project-a/tests/**`；具体路径见 [KM:reference.file-ownership](../indexes/file-ownership.md)。`taptap/` 仅保留为暂停原型。

## 验证

Godot M0 基线已通过 headless/GUT 验证；M1 durable state/commands，M2 随机英雄/四槽编队，M3 可重放战斗，M4 装备/任务/营地，M5 Android 设备证据按 Godot 路线推进。

## 相关节点

[KM:decision.durable-domain-kernel](../../decisions/ADR-0002-durable-domain-kernel.md)。

[KM:decision.project-a-game-root](../../decisions/ADR-0003-project-a-game-root.md)。

[KM:decision.godot-game-root-restored](../../decisions/ADR-0005-godot-game-root-restored.md)。

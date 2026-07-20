---
km_id: reference.architecture-overview
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - taptap/scripts/main.lua
  - taptap/scripts/game/GameState.lua
validated_by:
  - maker_build_current_directory
  - historical M0 headless and GUT verification
tags:
  - reference:architecture-overview
  - risk:planned-not-implemented
related:
  - decision.durable-domain-kernel
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - reference.state-command-lifecycle
  - reference.file-ownership
---

# 架构总览

> 当前实现已迁移到 TapTap Maker。Maker 原型可玩，但批准规划中的随机英雄、四槽编队、随机装备和可重放领域门禁仍未落地，因此本节点保持 `draft`。

## 目标

用小型 Lua 领域内核承载状态、战斗、任务、离线和持久化语义，用 UrhoX 运行时和 `urhox-libs/UI` 负责生命周期与纯 2D 表现。

## 事实

- 继续采用领域内核 + 薄运行时外壳，按 vertical slice milestone 交付；语言和外壳已由 Godot/GDScript 迁移为 Maker/UrhoX Lua。
- UI Widget 与表现组件不得成为持久状态真值。
- 不引入 DI 框架、ECS、数据库或自定义编辑器框架。
- `scripts/main.lua` 只负责生命周期和 Update；`GameState.lua` 是当前状态事实源，`GameUI.lua` 与 `BattleView2D.lua` 只投影和表现。
- 本地 JSON 与 `clientCloud` 当前同时存在；后续 command/receipt 语义仍需补齐。
- 持久 `GameState` 与临时 `BattleSession/BattleState` 分离；只有 `BattleResult` 进入结算。
- 领域逻辑必须可在无 UI 的 Lua 测试/模拟中运行；UI 通过方法调用投影状态。

## 入口或路径

当前入口为 [CODE:taptap-main](../../../taptap/scripts/main.lua)、[CODE:taptap-state](../../../taptap/scripts/game/GameState.lua) 和 [CODE:taptap-ui](../../../taptap/scripts/ui/GameUI.lua)；历史 Godot M0 入口保留在 `project-a/`。其余规划目录见 [KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

TapTap 迁移基线已通过 MCP 远端构建；M1 durable state/commands，M2 随机英雄/四槽编队，M3 可重放战斗，M4 装备/任务/营地，M5 Android 设备证据待实现。

## 相关节点

[KM:decision.durable-domain-kernel](../../decisions/ADR-0002-durable-domain-kernel.md)。

[KM:decision.project-a-game-root](../../decisions/ADR-0003-project-a-game-root.md)。

[KM:decision.taptap-maker-game-root](../../decisions/ADR-0004-taptap-maker-game-root.md)。

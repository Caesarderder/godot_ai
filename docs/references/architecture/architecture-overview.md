---
km_id: reference.architecture-overview
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - taptap/scripts/main.lua
  - taptap/scripts/game/GameState.lua
validated_by:
  - Godot 4.7.1 editor session for project-a
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - maker_build_current_directory
  - M0 headless and GUT verification
tags:
  - reference:architecture-overview
  - risk:planned-not-implemented
related:
  - decision.durable-domain-kernel
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - decision.return-to-project-a
  - reference.state-command-lifecycle
  - reference.file-ownership
---

# 架构总览

> 当前实现核心已回到 `project-a/` Godot 工程。Godot M0 shell 已验证，但批准规划中的随机英雄、四槽编队、随机装备和可重放领域门禁仍未落地，因此本节点保持 `draft`。TapTap Maker 原型只作为参考实现保留。

## 目标

用小型 GDScript 领域内核承载状态、战斗、任务、离线和持久化语义，用 Godot Node、Resource、Autoload 与 Control 负责生命周期、内容和纯 2D 表现。

## 事实

- 继续采用领域内核 + 薄 Godot 外壳，按 vertical slice milestone 交付；Godot/GDScript 是当前默认语言和运行时。
- Control 与表现节点不得成为持久状态真值。
- 不引入 DI 框架、ECS、数据库或自定义编辑器框架。
- `project-a/game/scripts/autoloads/**` 只承担跨场景服务与编排；领域状态、命令和表现层继续分离。
- M0 已有 `SaveManager`、`ContentCatalog`、`EventBus`、`Game` 和 `AppLifecycle` Autoload；后续 command/receipt 与领域模型仍需补齐。
- 持久 `GameState` 与临时 `BattleSession/BattleState` 分离；只有 `BattleResult` 进入结算。
- 领域逻辑必须可在无 UI 的 GUT/headless 测试与模拟中运行；UI 通过信号和查询投影状态。
- TapTap 原型中的自动战斗、离线收益、培养和手机 UI 只能作为需求与行为参考，不能成为 Godot 的状态真值或完成证据。

## 入口或路径

当前工程入口为 [CODE:godot-project](../../../project-a/project.godot) 和 `project-a/game/scenes/app/main.tscn`，M0 验证入口为 [CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)。TapTap 参考入口仍为 [CODE:taptap-main](../../../taptap/scripts/main.lua)；其余规划目录见 [KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

Godot M0 已通过 headless 与 GUT 基线；M1 durable state/commands，M2 随机英雄/四槽编队，M3 可重放战斗，M4 装备/任务/营地，M5 Android 设备证据待实现。TapTap 原型的远端构建记录继续作为参考原型证据保留。

## 相关节点

[KM:decision.durable-domain-kernel](../../decisions/ADR-0002-durable-domain-kernel.md)。

[KM:decision.project-a-game-root](../../decisions/ADR-0003-project-a-game-root.md)。

[KM:decision.taptap-maker-game-root](../../decisions/ADR-0004-taptap-maker-game-root.md)。

[KM:decision.return-to-project-a](../../decisions/ADR-0005-return-to-project-a.md)。

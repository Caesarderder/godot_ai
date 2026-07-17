---
km_id: reference.architecture-overview
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
validated_by:
  - M0 headless and GUT verification
tags:
  - reference:architecture-overview
  - risk:planned-not-implemented
related:
  - decision.durable-domain-kernel
  - decision.project-a-game-root
  - reference.state-command-lifecycle
  - reference.file-ownership
---

# 架构总览

> 架构已经规划批准，M0 的薄 Godot 外壳、Autoload 顺序与验证门禁已落地；M1-M5 领域内核尚不存在，因此本节点保持 `draft`。

## 目标

用小型领域内核承载状态、战斗、任务、离线和持久化语义，用 Godot Node/Control 负责生命周期与表现。

## 事实

- 选择 A1+B1：领域内核 + 薄 Godot 外壳，按 vertical slice milestone 交付。
- Node/场景可作为表现层，不得成为持久状态真值。
- 不引入 DI 框架、ECS、数据库或自定义编辑器框架。
- 已验证 Autoload 顺序：`_mcp_game_helper` -> SystemClock -> SaveManager -> ContentCatalog -> EventBus -> Game -> AppLifecycle。
- `res://addons/godot_ai/plugin.cfg` 与 `res://addons/gut/plugin.cfg` 共存；游戏代码不依赖工具插件内部实现。
- 持久 `GameState` 与临时 `BattleSession/BattleState` 分离；只有 `BattleResult` 进入结算。
- 领域逻辑必须能 headless 运行；UI 通过 presenter/controller 投影状态。

## 入口或路径

M0 入口为 [CODE:project-config](../../../project-a/project.godot)、[CODE:main-scene](../../../project-a/game/scenes/app/main.tscn) 和 [CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)；其余规划目录见 [KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

M0 headless shell/Autoload 已通过；M1 state/save/commands，M2 heroes，M3 battle，M4 meta，M5 Android 待实现；全部完成后把本节点转为 `active`。

## 相关节点

[KM:decision.durable-domain-kernel](../../decisions/ADR-0002-durable-domain-kernel.md)。

[KM:decision.project-a-game-root](../../decisions/ADR-0003-project-a-game-root.md)。

---
km_id: decision.return-to-project-a
km_type: decision
domain: architecture
status: deprecated
owner: maintainers
last_verified: 2026-07-25
source_of_truth:
  - docs/decisions/ADR-0005-project-a-web-3d-root.md
validated_by:
  - manual-deprecation-review
tags:
  - decision:project-root
  - risk:worktree-boundary
related:
  - decision.project-a-web-3d-root
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - reference.architecture-overview
  - reference.file-ownership
  - reference.implementation-status
---

# ADR-0005：恢复 project-a 作为当前游戏工程根

## 状态

Deprecated，2026-07-25。本文保留 2026-07-23 的历史决策语境；当前引擎版本、渲染器、维度和发布目标由 [KM:decision.project-a-web-3d-root](ADR-0005-project-a-web-3d-root.md) 取代。

## 决策

当前工作目标、工程核心和后续玩法默认落点统一回到 `project-a/` Godot 4.7.1 工程。玩法代码与资源进入 `project-a/game/**`，测试进入 `project-a/tests/**`，工程工具进入 `project-a/tools/**`，构建产物进入 `project-a/build/**`。

`taptap/` 不删除、不机械翻译，也不作为默认实现继续扩展；它保留为已验证的玩法、数值、手机 UI 和 2D 表现参考。需要复用其行为时，先提炼产品语义与测试，再按 Godot 的 Resource、Node、Autoload 和 GUT 边界重新实现。

现有 `project-a/addons/godot_ai/**`、EditorPlugin 和 `_mcp_game_helper` Autoload 属于受保护工具层。任何 `project.godot` 修改都必须保留这些入口，并尊重工作树中的既有用户改动。

## 原因

用户明确要求把当前工作目标和核心转移到 `project-a` Godot 工程。该工程已有 Godot 4.7.1 Mobile 配置、M0 shell、自动加载层、GUT 验证和已连接的 Godot 编辑器会话，适合作为后续垂直切片的唯一默认工程根。

## 影响

- 所有新玩法、UI、存档、内容和验证任务默认先定位 `project-a/**`。
- Godot/GUT/Android 命令统一使用 `--path project-a` 或仓库内现有验证脚本。
- TapTap MCP 只用于维护或验证 `taptap/` 参考原型，不再是默认提交和构建通道。
- TapTap 原型已有功能只能作为参考证据，不能被表述为 Godot 当前已实现功能。
- 已批准的产品不变量和 M1-M5 目标不变；实现状态必须重新以 Godot 代码、测试与设备证据判断。

## 相关节点

[KM:reference.file-ownership](../references/indexes/file-ownership.md)、[KM:reference.implementation-status](../references/constraints/implementation-status.md)、[CMD:game-verification](../runbooks/game-verification.md#game-verification)。

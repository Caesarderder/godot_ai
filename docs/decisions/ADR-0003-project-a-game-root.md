---
km_id: decision.project-a-game-root
km_type: decision
domain: architecture
status: deprecated
owner: maintainers
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - user-confirmation
  - manual-project-scan
tags:
  - decision:project-root
  - risk:worktree-boundary
related:
  - decision.taptap-maker-game-root
  - decision.godot-game-root-restored
  - reference.architecture-overview
  - reference.file-ownership
  - reference.implementation-status
---

# ADR-0003：复用 project-a 作为游戏工程根

## 状态

Deprecated，2026-07-20。历史上曾由 [KM:decision.taptap-maker-game-root](ADR-0004-taptap-maker-game-root.md) 替代；其 `project-a/` 路径结论已由 [KM:decision.godot-game-root-restored](ADR-0005-godot-game-root-restored.md) 重新确认。

## 决策

不再创建独立根目录 `game/`。游戏直接在现有 `project-a/` Godot 工程中开发：玩法代码和资源进入 `project-a/game/**`，测试进入 `project-a/tests/**`，工程工具进入 `project-a/tools/**`，构建产物进入 `project-a/build/**`。

现有 `project-a/addons/godot_ai/**` 继续作为智能体工具插件使用；修改 `project.godot` 时必须保留该 EditorPlugin 和 `_mcp_game_helper` Autoload。

## 原因

用户明确指定 `project-a/` 就是目标工程。该工程已经具备 Godot 4.7 Mobile、Mobile renderer、拉伸配置和智能体插件底座，另建工程会制造重复配置和错误边界。

## 影响

- M0 从“新建工程”改为“在现有工程建立玩法 shell”。
- 保护边界从整个 `project-a/**` 收窄为现有 addon 和未分配用户路径。
- 所有 Godot/GUT/Android 命令使用 `--path project-a`。
- M1-M5 的规划、实现、测试和验证统一落在 `project-a/`；具体完成状态以实现状态索引和真实测试证据为准。

## 相关节点

[KM:reference.file-ownership](../references/indexes/file-ownership.md)、[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

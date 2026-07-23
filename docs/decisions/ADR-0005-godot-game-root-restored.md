---
km_id: decision.godot-game-root-restored
km_type: decision
domain: architecture
status: active
owner: maintainers
last_verified: 2026-07-21
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
validated_by:
  - user-confirmation
  - manual-project-scan
tags:
  - decision:project-root
  - risk:worktree-boundary
related:
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - reference.architecture-overview
  - reference.file-ownership
  - reference.implementation-status
---

# ADR-0005：恢复 Godot 作为当前游戏实现根

## 状态

Accepted，2026-07-21。替代 [KM:decision.taptap-maker-game-root](ADR-0004-taptap-maker-game-root.md)；重新确认 [KM:decision.project-a-game-root](ADR-0003-project-a-game-root.md) 中的 `project-a/` 路径边界。

## 决策

M1-M5 的规划、实现、测试、工具和构建统一使用现有 `project-a/` Godot 4.7.1 工程。玩法与资源进入 `project-a/game/**`，测试进入 `project-a/tests/**`，工具进入 `project-a/tools/**`，构建产物进入 `project-a/build/**`。

`taptap/` Maker 原型暂时搁置并原样保留。除非用户通过新的决策重新启用，否则它不是默认开发入口，也不能作为 Godot milestone 的实现或验收证据。

## 原因

用户要求把所有当前规划重新统一到 Godot，消除 PRD/GUT/Godot 实施计划与 TapTap 路由之间的双重事实源。`project-a/` 已有 M0 基线以及后续 M1-M3 代码和测试落点，继续沿该路线能复用批准的技术与验证契约。

## 影响

- Godot/GDScript/GUT 和 `--path project-a` 恢复为 M1-M5 的默认技术与验证约束。
- `project-a/addons/godot_ai/**` 继续作为受保护工具层；修改 `project.godot` 时必须保留既有插件和 `_mcp_game_helper` Autoload。
- TapTap 的提交、构建和原型能力只作为历史证据保留，不计入当前 milestone exit。
- 文件归属、代码定位、开发审查、验证矩阵和实现状态必须以 `project-a/` 为准。

## 相关节点

[KM:reference.file-ownership](../references/indexes/file-ownership.md)、[KM:reference.implementation-status](../references/constraints/implementation-status.md)、[CMD:game-verification](../runbooks/game-verification.md#game-verification)。

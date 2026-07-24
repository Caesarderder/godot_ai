---
km_id: decision.taptap-maker-game-root
km_type: decision
domain: architecture
status: deprecated
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - taptap/.maker-mcp/config.json
  - taptap/scripts/main.lua
  - taptap/README.md
validated_by:
  - user-confirmation
  - maker_status_lite
  - maker_build_current_directory
tags:
  - decision:project-root
  - risk:worktree-boundary
related:
  - decision.project-a-game-root
  - decision.return-to-project-a
  - reference.architecture-overview
  - reference.file-ownership
  - reference.implementation-status
---

# ADR-0004：迁移到 taptap 作为当前游戏实现根

## 状态

Deprecated，2026-07-23。该决策曾在 2026-07-20 替代 [KM:decision.project-a-game-root](ADR-0003-project-a-game-root.md)，现由 [KM:decision.return-to-project-a](ADR-0005-return-to-project-a.md) 替代。

## 决策

后续可玩版本优先在独立的 `taptap/` TapTap Maker 工程开发，运行时采用 UrhoX Lua 和 `urhox-libs/UI`，保持手机端、单机、纯 2D。`project-a/` 不删除，继续作为已验证的 Godot M0 历史基线和迁移对照，不再是默认玩法落点。

TapTap 工程拥有独立 Maker Git 边界。状态、提交、推送、预览与构建统一使用 `maker_status_lite` 和 `maker_build_current_directory`，不得用父仓库普通 Git 流程替代 Maker 提交。

## 原因

用户明确要求在当前仓库下新建 `taptap/`，并改用 TapTap MCP 完成 2D 手机游戏开发。绑定的 Maker 项目已有可玩原型，保留并继续演进比从 Godot 代码机械翻译更安全。

## 影响

- 新的运行入口是 `taptap/scripts/main.lua`。
- 领域、UI、配置和素材分别进入 `taptap/scripts/**` 与 `taptap/assets/**`。
- Godot 专属 Resource、Node、Autoload 和 GUT 约束只适用于历史基线，不再约束新的 Maker 实现。
- 领域不变量继续有效：随机英雄、四槽编队、装备优先于薄营地、任务自由引导。
- 迁移后的首次 Maker 提交与远端构建已成功，提交为 `cd5fa47`。

## 相关节点

[KM:reference.file-ownership](../references/indexes/file-ownership.md)、[KM:reference.implementation-status](../references/constraints/implementation-status.md)、[CMD:game-verification](../runbooks/game-verification.md#game-verification)。

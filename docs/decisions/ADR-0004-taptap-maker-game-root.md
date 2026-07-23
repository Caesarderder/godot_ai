---
km_id: decision.taptap-maker-game-root
km_type: decision
domain: architecture
status: deprecated
owner: maintainers
last_verified: 2026-07-20
source_of_truth:
  - README.md
  - docs/decisions/ADR-0005-godot-game-root-restored.md
validated_by:
  - user-confirmation
  - maker_status_lite
  - maker_build_current_directory
tags:
  - decision:project-root
  - risk:worktree-boundary
related:
  - decision.project-a-game-root
  - decision.godot-game-root-restored
  - reference.architecture-overview
  - reference.file-ownership
  - reference.implementation-status
---

# ADR-0004：迁移到 taptap 作为当前游戏实现根

## 状态

Deprecated，2026-07-21。已由 [KM:decision.godot-game-root-restored](ADR-0005-godot-game-root-restored.md) 替代；TapTap Maker 路线暂时搁置。本 ADR 只保留迁移历史，不再指导新功能落点。

## 决策

2026-07-20 曾决定优先在独立的 `taptap/` TapTap Maker 工程开发。2026-07-21 用户决定暂时搁置该路线，后续规划与实现全部回到 `project-a/` Godot 工程。

`taptap/` 及其 Maker Git 边界继续保留，除非用户重新启用该路线，否则不得把它作为 M1-M5 的实现、测试或验收入口。

## 原因

用户明确要求在当前仓库下新建 `taptap/`，并改用 TapTap MCP 完成 2D 手机游戏开发。绑定的 Maker 项目已有可玩原型，保留并继续演进比从 Godot 代码机械翻译更安全。

## 影响

- `taptap/scripts/**` 与 `taptap/assets/**` 作为暂停原型保留，不接收当前里程碑功能。
- Godot Resource、Node、Autoload、GDScript 和 GUT 再次约束当前实现。
- 规划代码、资源、测试和工具分别进入 `project-a/game/**`、`project-a/tests/**` 与 `project-a/tools/**`。
- 领域不变量继续有效：随机英雄、四槽编队、装备优先于薄营地、任务自由引导。
- 历史 Maker 提交 `cd5fa47` 与远端构建证据继续保留，但不计入当前 Godot milestone exit。

## 相关节点

[KM:reference.file-ownership](../references/indexes/file-ownership.md)、[KM:reference.implementation-status](../references/constraints/implementation-status.md)、[CMD:game-verification](../runbooks/game-verification.md#game-verification)。

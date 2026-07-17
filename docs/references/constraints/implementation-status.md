---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - README.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - rg --files
  - manual-repository-scan
tags:
  - reference:implementation-status
  - risk:planned-not-implemented
related:
  - reference.file-ownership
  - quality.stale-docs
---

# 实现状态基线

## 目标

防止知识地图把批准规划误写成已经实现的系统。

## 事实

- 已存在：`.omx` 需求/PRD/测试规格、`docs/` 知识地图，以及目标 Godot 工程 `project-a/`；其 `project.godot` 已配置 Godot 4.7 Mobile、Mobile renderer、canvas_items/expand、godot_ai EditorPlugin 与 `_mcp_game_helper` Autoload。
- 尚不存在：`project-a/game/**` 玩法源码/场景/Resources、`project-a/tests/**`、GUT、fixtures、Android 导出配置和设备证据。
- `project-a/addons/godot_ai/**` 是现有智能体工具插件并含用户工作树改动；它属于目标工程的工具层，不是游戏领域代码，默认不得被游戏任务修改/格式化/清理。
- 所有指向未来 `project-a/game/**`、`project-a/tests/**`、`project-a/tools/**` 的描述都是“规划落点”，禁止使用 `CODE:*` 标签，直到路径实际存在。

## 入口或路径

[CODE:repository-readme](../../../README.md)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

每个 milestone 前后检查 `project-a/project.godot`、`rg --files project-a/game project-a/tests project-a/tools` 和受保护 addon/worktree baseline；路径落地后更新本节点与相关 `draft` 状态。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

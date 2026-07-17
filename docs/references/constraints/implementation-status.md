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

- 已存在：`.omx` 需求、访谈、PRD、测试规格和规划状态；`docs/` 知识地图；`project-a/` Godot AI 插件工程。
- 尚不存在：新游戏 `game/` 子项目、游戏源码、场景、Resources、GUT tests、fixtures、Android 导出配置和设备证据。
- `project-a/**` 是无关且含用户工作树改动的既存区域；不得作为游戏底座，也不得被本项目任务清理/格式化/暂存。
- 所有指向未来 `game/**` 的描述都是“规划落点”，禁止使用 `CODE:*` 标签，直到路径实际存在。

## 入口或路径

[CODE:repository-readme](../../../README.md)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

每个 milestone 前后运行 `rg --files game`（不存在是当前预期）和 worktree baseline；路径落地后更新本节点与相关 `draft` 状态。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

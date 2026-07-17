---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - docs/workflows/knowledge-map-maintenance.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - memory:index
related:
  - workflow.knowledge-map-maintenance
  - quality.stale-docs
---

# 项目记忆入口

## 目标

只保存经过验证、会改变未来工作方式的重复经验；不保存聊天记录、猜测或一次性 debug 过程。

## 已验证经验

- 用户已明确 `project-a/` 就是目标 Godot 工程；不得再规划独立仓库根 `game/`。玩法隔离到 `project-a/game/**`，现有工具插件隔离在 `project-a/addons/godot_ai/**`。
- 当前产品/架构文档是批准规划，但 `project-a/game/**` 尚不存在；路径、命令和测试结果不能提前宣称已实现。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

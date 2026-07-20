---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-20
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

- 用户已把当前实现根迁移到 `taptap/` TapTap Maker 2D 工程；玩法进入 `taptap/scripts/**`，素材进入 `taptap/assets/**`，提交/构建只走 Maker MCP。
- `project-a/` 保留为 Godot 历史 M0 和工具插件基线，不再承接默认玩法开发；规划路径、命令和测试结果仍不能提前宣称已实现。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

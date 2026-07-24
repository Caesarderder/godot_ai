---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-23
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

- 用户已把当前工作目标、工程核心和默认实现根转回 `project-a/` Godot 4.7.1 工程；后续玩法、UI、测试和构建优先进入该工程。
- `taptap/` 完整保留为 Maker 2D 参考原型，不再承接默认开发；参考原型已有功能不能提前宣称为 Godot 已实现。
- `project-a/addons/godot_ai/**` 与相关 EditorPlugin/Autoload 是受保护工具层；规划路径、命令和测试结果仍不能提前宣称已实现。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-21
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

- 用户已恢复 `project-a/` 为当前 Godot 4.7.1 实现根；M1-M5 的规划、玩法、测试、工具和验证统一在 Godot 工程推进。
- `taptap/` Maker 原型暂时搁置，只保留历史参考，不能用其代码或构建结果证明 Godot milestone 完成；规划路径、命令和测试结果仍不能提前宣称已实现。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

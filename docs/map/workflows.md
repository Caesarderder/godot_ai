---
km_id: map.workflows
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - docs/workflows
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:task-routing
related:
  - workflow.knowledge-query
  - workflow.code-locating
  - workflow.impact-map
  - workflow.code-writing-review
  - workflow.knowledge-map-maintenance
---

# 工作流索引

先选工作流，再读取最小必要节点；不要一次展开整棵地图。

| 任务 | 工作流 |
|---|---|
| 回答系统事实、产品边界 | [KM:workflow.knowledge-query](../workflows/knowledge-query.md) |
| 定位实现文件或归属 | [KM:workflow.code-locating](../workflows/code-locating.md) |
| 写代码、审查、重构、迁移前 | [KM:workflow.impact-map](../workflows/impact-map.md) |
| 实施或代码审查 | [KM:workflow.code-writing-review](../workflows/code-writing-review.md) |
| 新增/更新/审查知识节点 | [KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md) |

当前实现优先定位 `project-a/game/**`、`project-a/tests/**`、`project-a/tools/**` 与 `project-a/project.godot`；Godot 工程验证遵循 [CMD:game-verification](../runbooks/game-verification.md#game-verification)。`taptap/` 只作为已验证参考原型读取；未来 Godot 领域路径不存在时报告“规划落点”，不得把 TapTap 原型功能伪装成 Godot 已实现事实。

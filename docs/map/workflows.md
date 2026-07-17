---
km_id: map.workflows
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-17
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

当前 `project-a/` 工程已存在，但 `project-a/game/**` 玩法尚未实现。代码定位任务必须区分现有 addon 工具代码与规划玩法路径；不存在时报告“规划落点”，不得伪装成现有实现。

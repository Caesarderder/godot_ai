---
km_id: map.workflows
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-25
source_of_truth:
  - docs/workflows
validated_by:
  - python3 tools/docs_lint.py
  - manual-skill-routing-review
tags:
  - workflow:task-routing
related:
  - workflow.knowledge-query
  - workflow.skill-routing
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
| 为任务选择项目 Skill | [KM:workflow.skill-routing](../workflows/skill-routing.md) |
| 定位实现文件或归属 | [KM:workflow.code-locating](../workflows/code-locating.md) |
| 写代码、审查、重构、迁移前 | [KM:workflow.impact-map](../workflows/impact-map.md) |
| 实施或代码审查 | [KM:workflow.code-writing-review](../workflows/code-writing-review.md) |
| 新增/更新/审查知识节点 | [KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md) |

实现定位必须先读取当前文件归属索引与工程配置；参考原型、规划落点和已实现事实必须显式区分。若实现树或知识节点仍有合并冲突，先报告冲突，不从任一侧推断当前事实。

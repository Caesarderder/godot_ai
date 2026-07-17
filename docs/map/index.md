---
km_id: map.control-index
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - docs/index.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:knowledge-query
  - quality:docs-routing
related:
  - map.public-index
  - map.schema
  - map.workflows
  - map.domains
  - invariant.project-boundaries
---

# 知识地图控制入口

## 阅读顺序

仓库入口 -> [KM:map.schema](schema.md) -> [KM:invariant.project-boundaries](invariants.md) -> [KM:map.workflows](workflows.md) -> 任务相关领域 -> 实现/验证参考。

## 工作环境分层

| 层 | 入口 | 用途 |
|---|---|---|
| 控制层 | 本页、[KM:map.schema](schema.md) | 读法和节点契约 |
| 领域层 | [KM:map.domains](domains.md) | 系统职责和反边界 |
| 工作流层 | [KM:map.workflows](workflows.md) | 任务步骤、停止条件、验证 |
| 约束层 | [KM:invariant.project-boundaries](invariants.md) | 不可破坏的边界 |
| 参考层 | [KM:reference.architecture-overview](../references/architecture/architecture-overview.md) | 架构、文件归属和验证证据 |
| 决策层 | [KM:decision.durable-domain-kernel](../decisions/ADR-0002-durable-domain-kernel.md) | 长期取舍 |
| 反馈层 | [KM:memory.index](../memory/index.md) | 已验证经验 |
| 质量层 | [KM:quality.lint-rules](../quality/lint-rules.md) | 漂移检测 |

## 常用入口

- 查事实：[KM:workflow.knowledge-query](../workflows/knowledge-query.md)
- 找代码：[KM:workflow.code-locating](../workflows/code-locating.md)
- 开工影响分析：[KM:workflow.impact-map](../workflows/impact-map.md)
- 写代码/审查：[KM:workflow.code-writing-review](../workflows/code-writing-review.md)
- 维护地图：[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)

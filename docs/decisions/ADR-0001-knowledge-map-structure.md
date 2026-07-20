---
km_id: decision.knowledge-map-structure
km_type: decision
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-20
source_of_truth:
  - docs/index.md
  - tools/docs_lint.py
validated_by:
  - caesar-docs:init
  - python3 tools/docs_lint.py
tags:
  - decision:knowledge-map-structure
related:
  - map.public-index
  - map.schema
  - workflow.knowledge-map-maintenance
---

# ADR-0001：知识地图结构

## 状态

Accepted，2026-07-17。

## 决策

采用 `docs/` 控制/领域/工作流/参考/决策/runbook/质量/memory 分层，所有 Markdown 使用可 lint 的 frontmatter；README 只路由到地图，不承载完整事实。

## 原因

本决策建立于 2026-07-17，当时仓库只有批准规划和占位 README；此后实现根变化不影响知识地图分层。人和智能体仍需共享事实优先级，并明确区分规划与实现；当前实现根以 ADR-0004 为准。

## 影响

- 已批准产品约束可为 `active`。
- 任何未来实现节点在真实路径和验证证据落地前必须为 `draft`；当前路径由文件归属索引与最新工程根 ADR 决定。
- 不存在的 AGENTS.md/ARCHITECTURE.md 不自动创建。
- 所有文档变更必须通过 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

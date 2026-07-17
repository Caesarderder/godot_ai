---
km_id: decision.knowledge-map-structure
km_type: decision
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-17
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

仓库当前只有批准规划和一个占位 README，游戏源码尚未创建。需要让人和智能体共享事实优先级，并明确区分规划与实现。

## 影响

- 已批准产品约束可为 `active`。
- 未来 `game/**` 实现节点在路径和测试落地前必须为 `draft`。
- 不存在的 AGENTS.md/ARCHITECTURE.md 不自动创建。
- 所有文档变更必须通过 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

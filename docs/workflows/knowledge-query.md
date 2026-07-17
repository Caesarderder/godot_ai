---
km_id: workflow.knowledge-query
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - docs/index.md
  - docs/map/index.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:knowledge-query
related:
  - map.control-index
  - map.domains
---

# 知识查询工作流

## 目标

用最少节点回答问题，并区分“已实现事实”“批准规划”“待确认假设”。

## 输入

用户问题、指向的系统/文件/命令，以及期望的事实精度。

## 步骤

1. 读 [KM:map.control-index](../map/index.md) 和 [KM:invariant.project-boundaries](../map/invariants.md)。
2. 在 [KM:map.domains](../map/domains.md) 选择一个主领域。
3. 优先读取实现索引和当前代码；若 `game/` 尚不存在，再读取规划参考。
4. 发现冲突时按事实优先级报告，不静默拼接。
5. 回答中明确状态：`active`、`draft`、`stale` 或待用户确认。

## 停止条件

已经找到足以回答问题的最小事实链；不要为了一个问题遍历全部 docs。

## 验证

路径和命令问题必须实际检查；规划数字至少追溯到 PRD/Test Spec。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)、[KM:reference.file-ownership](../references/indexes/file-ownership.md)。

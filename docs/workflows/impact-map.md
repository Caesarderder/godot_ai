---
km_id: workflow.impact-map
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - docs/map/invariants.md
  - docs/references/indexes/file-ownership.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:impact-map
  - risk:scope-drift
related:
  - invariant.project-boundaries
  - reference.file-ownership
---

# Impact Map 工作流

## 目标

写代码、修 bug、审查、重构、迁移或改知识地图前，先基于真实仓库约束影响范围。

## 输入

任务、触发原因、用户指定范围。

## 步骤

按以下模板输出简短 impact map：

```text
任务：
触发原因：
受影响领域：
需要先读的文件：
可能修改的文件：
必须保持的不变量：
验证方式：
可能需要同步更新的文档：
风险：
需要人确认的决策：
```

先用 [KM:map.domains](../map/domains.md) 判断领域，再用 [KM:reference.file-ownership](../references/indexes/file-ownership.md) 判断落点；未知项写“待确认”和验证方式。

## 停止条件

最小影响范围、关键不变量、验证和人类确认项已经清楚。

## 验证

任务结束后对比实际修改与 impact map；超出范围时更新地图并说明偏差。

## 相关节点

[KM:workflow.code-writing-review](code-writing-review.md)、[KM:workflow.knowledge-map-maintenance](knowledge-map-maintenance.md)。

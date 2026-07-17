---
km_id: workflow.knowledge-map-maintenance
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - docs/map/schema.md
  - tools/docs_lint.py
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:knowledge-map-maintenance
  - quality:docs-drift
related:
  - map.schema
  - quality.stale-docs
  - runbook.docs-lint
---

# 知识地图维护工作流

## 目标

让知识地图随代码、架构、工作流和验证证据演进，不产生平行事实源。

## 输入

代码/配置/测试变更、架构决策、重复误判或过期节点。

## 步骤

1. 读公共入口、控制入口和目标目录索引。
2. 优先更新已有节点，不创建同义节点。
3. 更新 frontmatter、`source_of_truth`、`validated_by`、`related`、tags 和正文。
4. 新增节点时同步相关索引与反向关系。
5. 未验证实现标 `draft`；冲突事实标 `stale`；历史替代标 `deprecated`。
6. 只有验证过且会改变未来行为的经验才写入 `docs/memory/`。
7. 运行 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)，并执行受影响项目测试。

## 停止条件

节点、索引、入口和验证证据一致；没有无法解释的 broken link 或 stale claim。

## 验证

`python3 tools/docs_lint.py` 零错误；必要时更新 [KM:quality.stale-docs](../quality/stale-docs.md)。

## 相关节点

[KM:quality.lint-rules](../quality/lint-rules.md)、[KM:memory.index](../memory/index.md)。

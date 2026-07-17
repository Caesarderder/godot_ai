---
km_id: quality.lint-rules
km_type: quality
domain: quality
status: active
owner: verification
last_verified: 2026-07-17
source_of_truth:
  - tools/docs_lint.py
validated_by:
  - python3 tools/docs_lint.py
tags:
  - quality:lint-rules
  - lint:frontmatter
  - lint:links
related:
  - map.schema
  - runbook.docs-lint
  - quality.stale-docs
---

# 知识地图 Lint 规则

## 检查目标

- 每个 Markdown 都有合法 frontmatter 和全部必填字段。
- `km_id` 唯一，`km_type/status/domain` 合法，日期格式正确。
- `related`、`KM:*`、相对链接、`CODE:*`、`CMD:*` 可解析。
- `source_of_truth` 仓库路径存在，或显式标为 `command:`。
- tag 使用已允许前缀，`domain:<name>` 对应注册领域。
- 最小启动集完整，不残留已删除目录链接。

## 检查方法

[CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。普通 `rg/find` 只用于枚举，不能替代可失败 lint。

## 失败处理

阻止知识地图交付；修复节点、索引或证据后重新运行。不得用忽略列表掩盖未知错误。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。

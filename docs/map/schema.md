---
km_id: map.schema
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - tools/docs_lint.py
validated_by:
  - python3 tools/docs_lint.py
tags:
  - quality:node-schema
  - lint:frontmatter
related:
  - map.control-index
  - quality.lint-rules
---

# 节点 Schema

## 必填 frontmatter

每个 `docs/**/*.md` 必须包含：`km_id`、`km_type`、`domain`、`status`、`owner`、`last_verified`、`source_of_truth`、`validated_by`、`tags`、`related`。

- `km_id`：唯一，格式 `{km_type}.{slug}`。
- `km_type`：`map|domain|workflow|invariant|decision|runbook|quality|reference|memory`。
- `status`：`active|draft|stale|deprecated`。
- `domain`：只能使用 [KM:map.domains](domains.md) 注册值。
- `last_verified`：`YYYY-MM-DD`。
- `source_of_truth`：仓库相对路径或明确的 `command:` 项。
- `related`：只能引用已存在的 `km_id`。

## 项目领域枚举

通用领域：`product`、`code`、`architecture`、`workflow`、`quality`、`agent-memory`、`cross-domain`。

项目领域：`hero-formation`、`battle-progression`、`equipment-economy`、`camp-quests`、`platform-persistence`。

## 状态规则

- `active`：有当前代码/配置/测试或用户批准规划支撑。
- `draft`：方向已规划但实现尚未存在，或证据仍不足。
- `stale`：已知与当前事实不一致，等待修复。
- `deprecated`：保留历史路由，并指向替代节点。

## 链接标签

- `KM:*` 指向唯一知识节点。
- `CODE:*` 只能指向实际存在的仓库路径。
- `CMD:*` 指向 runbook 中存在的锚点。

完整机器检查见 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

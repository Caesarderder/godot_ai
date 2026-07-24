---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - docs/references/constraints/implementation-status.md
validated_by:
  - manual-repository-scan
tags:
  - quality:stale-docs
  - risk:planned-not-implemented
related:
  - reference.implementation-status
  - workflow.knowledge-map-maintenance
---

# 过期与待回填文档

## 当前清单

ADR-0003 与 ADR-0004 均保留为 `deprecated` 历史决策，当前工程根由 ADR-0005 决定。以下 `draft` 是有意状态：

- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md)：Godot M0 已验证，批准领域内核仍未全部落地；TapTap 仅为参考原型。
- [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)：M1 状态/命令/存档未落地。
- [KM:reference.file-ownership](../references/indexes/file-ownership.md)：Godot M0 当前路径已验证，其余 Godot 规划路径未验证。
- [KM:domain.battle-progression](../domains/battle-progression.md)：原型自动战斗已存在，可重放 seed 与统计门禁未落地。
- [KM:domain.platform-persistence](../domains/platform-persistence.md)：原型存档/离线已存在，M1 durable 语义与设备证据未落地。
- [KM:runbook.game-verification](../runbooks/game-verification.md)：Godot 当前 M0 和 TapTap 参考构建已有证据，M1-M5/Android 命令待落地。

## 回填节奏

- M0：Godot 4.7.1 Mobile shell、Autoload、Safe Area、GUT 与 headless 基线。
- M1：command/time/save/offline/receipt。
- M2：英雄/编队。
- M3：战斗/seed/paired 1000。
- M4：装备/经济/任务/营地。
- M5：Android、性能、5 人证据。

## 验证

每次把 `draft` 改为 `active` 前，必须有真实代码/配置/测试和实际运行的 `validated_by`。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
last_verified: 2026-07-20
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

ADR-0003 与 ADR-0004 均作为历史决策保留；当前路线由 ADR-0005 恢复为 `project-a/` Godot。以下 `draft` 是有意状态：

- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md)：Godot 路线已恢复，批准领域内核仍未全部验证完成。
- [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)：M1 相关路径已出现，但状态/命令/存档里程碑尚未完成验证。
- [KM:reference.file-ownership](../references/indexes/file-ownership.md)：Godot 当前路径与规划落点并存，完成状态需按 milestone 验证。
- [KM:domain.battle-progression](../domains/battle-progression.md)：M3 相关路径已出现，可重放 seed 与统计门禁尚未完成验证。
- [KM:domain.platform-persistence](../domains/platform-persistence.md)：M1 相关路径已出现，durable 语义与设备证据尚未完成验证。
- [KM:runbook.game-verification](../runbooks/game-verification.md)：Godot M0 已运行，M1-M5/Android 命令与证据待逐步确认。

## 回填节奏

- M0：Godot 工程 shell、Safe Area、Autoload、GUT 与 headless baseline。
- M1：command/time/save/offline/receipt。
- M2：英雄/编队。
- M3：战斗/seed/paired 1000。
- M4：装备/经济/任务/营地。
- M5：Android、性能、5 人证据。

## 验证

每次把 `draft` 改为 `active` 前，必须有真实代码/配置/测试和实际运行的 `validated_by`。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

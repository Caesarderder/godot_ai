---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
last_verified: 2026-07-17
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

没有已知 `stale` 节点；以下 `draft` 是有意状态：

- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md)：M0-M5 实现未落地。
- [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)：M1 状态/命令/存档未落地。
- [KM:reference.file-ownership](../references/indexes/file-ownership.md)：规划路径尚未验证。
- [KM:domain.battle-progression](../domains/battle-progression.md)：M3 战斗未落地。
- [KM:domain.platform-persistence](../domains/platform-persistence.md)：M0/M1/M5 平台与持久化未落地。
- [KM:runbook.game-verification](../runbooks/game-verification.md)：Godot/Android 命令未运行。

## 回填节奏

- M0：项目配置、renderer、Autoload、Safe Area、GUT。
- M1：command/time/save/offline/receipt。
- M2：英雄/编队。
- M3：战斗/seed/paired 1000。
- M4：装备/经济/任务/营地。
- M5：Android、性能、5 人证据。

## 验证

每次把 `draft` 改为 `active` 前，必须有真实代码/配置/测试和实际运行的 `validated_by`。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

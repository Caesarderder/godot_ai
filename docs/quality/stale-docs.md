---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
last_verified: 2026-07-24
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

ADR-0003、ADR-0004 已明确标记 `deprecated`，由 ADR-0005 替代。以下 `draft` 是有意状态：

- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md)：Compatibility、v4 Meta、25 关、营地目标中心、任务/成就、设置/失焦暂停、Web/PWA 本地候选已落地；生产源持久化、装备、离线战斗和真机证据仍未完成。
- [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)：v4 状态、公开命令、存档、工厂/合成、战斗结算、任务生命周期和成就生命周期已落地；internal Web lifecycle、离线和装备生命周期仍未完成。
- [KM:reference.file-ownership](../references/indexes/file-ownership.md)：Godot shell、v4 Meta、工厂/培育、六人编队、任务/成就和战斗路径已验证，其余规划路径未验证。
- [KM:domain.platform-persistence](../domains/platform-persistence.md)：本地严格 JSON、主备恢复、设置存储、焦点/可见性和本地浏览器证据已落地；生产源持久性、离线结算与真机证据未落地。
- [KM:runbook.game-verification](../runbooks/game-verification.md)：Godot shell smoke、Meta suite、battle suite 与横屏截图已运行；Web M0、跨帧率 digest、paired balance 和设备命令待落地。

## 回填节奏

- M0：音频解锁、持久性探测和手机浏览器真机 smoke；Web/PWA preset 与本地 844×390 smoke 已完成。
- M1：internal WebLifecycle、离线结算、浏览器 crash/replay 和完整时间语义证据。
- M2：工厂/培育/编队交互与真人可读性观察。
- M3：跨帧率 digest、战斗 seed、paired 1000。
- M4：目标中心、任务/成就和战功已落地；装备、设施、离线经济继续回填。
- M5：Web/PWA、手机浏览器性能、更新恢复和 5 人证据。

## 验证

每次把 `draft` 改为 `active` 前，必须有真实代码/配置/测试和实际运行的 `validated_by`。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

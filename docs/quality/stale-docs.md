---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
<<<<<<< HEAD
last_verified: 2026-07-24
=======
last_verified: 2026-07-23
>>>>>>> origin/codex/toilet-man-3d-idle
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

<<<<<<< HEAD
ADR-0003、ADR-0004 已明确标记 `deprecated`，由 ADR-0005 替代。以下 `draft` 是有意状态：

- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md)：Compatibility、v2 Meta、工厂/培育、六人编队和三阶段战斗已落地；Web/PWA、浏览器平台适配、装备、任务和离线仍未完成。
- [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)：v2 状态、公开命令、存档、工厂/合成和战斗结算已落地；internal Web lifecycle、离线、装备和任务生命周期仍未完成。
- [KM:reference.file-ownership](../references/indexes/file-ownership.md)：Godot shell、v2 Meta、工厂/培育、六人编队和战斗路径已验证，其余规划路径未验证。
- [KM:domain.platform-persistence](../domains/platform-persistence.md)：本地严格 JSON、主备恢复与 bootstrap 已落地；Web 持久性、生命周期、离线结算与浏览器证据未落地。
- [KM:runbook.game-verification](../runbooks/game-verification.md)：Godot shell smoke、Meta suite、battle suite 与横屏截图已运行；Web M0、跨帧率 digest、paired balance 和设备命令待落地。

## 回填节奏

- M0：Web preset、PWA、音频解锁、持久性探测和手机浏览器 smoke。
- M1：internal WebLifecycle、离线结算、浏览器 crash/replay 和完整时间语义证据。
- M2：工厂/培育/编队交互与真人可读性观察。
- M3：跨帧率 digest、战斗 seed、paired 1000。
=======
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
>>>>>>> origin/codex/toilet-man-3d-idle
- M4：装备/经济/任务/营地。
- M5：Web/PWA、手机浏览器性能、更新恢复和 5 人证据。

## 验证

每次把 `draft` 改为 `active` 前，必须有真实代码/配置/测试和实际运行的 `validated_by`。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

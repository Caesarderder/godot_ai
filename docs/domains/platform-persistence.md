---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
last_verified: 2026-07-21
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/game/scripts/autoloads
  - project-a/game/scripts/persistence
validated_by:
  - manual-project-scan
  - code-review
tags:
  - domain:platform-persistence
  - risk:mobile-lifecycle
  - risk:save-consistency
related:
  - reference.state-command-lifecycle
  - reference.verification-matrix
---

# 移动平台与持久化领域

> 当前实现与验收均以 `project-a/` Godot 为准。durable command、候选写入、备份恢复、离线结算和 Android 设备证据必须由 M1/M5 门禁确认，因此仍为 `draft`。

## 目标

在 Android 生命周期、杀进程和重复恢复下保持存档、离线收益和随机价值一致。

## 什么时候读

实现 Godot AppLifecycle、GameState、FileAccess 存档、离线、安全区或 Android 设备验证时。

## 职责

- Godot 4.7.1、GDScript、2D、手机端优先；`GameState` 通过 `FileAccess` 使用 versioned JSON 保存稳定 ID 与实例字段。
- pause/resume/heartbeat 统一走 sealed internal durable command。
- `offline_anchor_unix` 是唯一离线收益起点；回拨为 0，前跳封顶 8 小时。
- UI 使用 Godot Control 与安全区适配；物理 48dp 触控目标、旋转重算和 safe-area golden 属于移动端门禁。

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

Godot M0 基线已通过；M1/M5 继续验证 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、Safe Area golden 和三档 Android 真机。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

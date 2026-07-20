---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - taptap/scripts/game/GameState.lua
validated_by:
  - maker_build_current_directory
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

> TapTap 原型已有本地 JSON、`clientCloud` 和 8 小时离线收益；durable command、备份恢复和 Android 设备证据尚未落地，因此仍为 `draft`。

## 目标

在 Android 生命周期、杀进程和重复恢复下保持存档、离线收益和随机价值一致。

## 什么时候读

实现 Maker 生命周期、GameState、云/本地存档、离线、安全区或 Android 设备验证时。

## 职责

- UrhoX Lua、2D、手机端优先；`GameState` 使用 versioned JSON 保存稳定 ID 与实例字段。
- pause/resume/heartbeat 统一走 sealed internal durable command。
- `offline_anchor_unix` 是唯一离线收益起点；回拨为 0，前跳封顶 8 小时。
- UI 已采用 `urhox-libs/UI` 与 `UI.Scale.DEFAULT`；`UI.SafeAreaView` 和至少 48 基准像素的主要触控目标是后续必须补齐的移动端门禁，当前原型尚未满足。

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

当前迁移构建已通过；后续补 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、Safe Area golden、三档 Android 真机。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

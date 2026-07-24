---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/game/scripts/autoloads/save_manager.gd
  - project-a/game/scripts/autoloads/app_lifecycle.gd
  - taptap/scripts/game/GameState.lua
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
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

> 当前 Godot 工程已有 M0 `SaveManager`、`AppLifecycle`、Safe Area 和移动 shell，但 durable command、离线收益、备份恢复和 Android 设备证据尚未落地。TapTap 参考原型已有本地 JSON、`clientCloud` 和 8 小时离线收益，但不能作为 Godot 完成证据，因此本领域仍为 `draft`。

## 目标

在 Android 生命周期、杀进程和重复恢复下保持存档、离线收益和随机价值一致。

## 什么时候读

实现 Godot 移动生命周期、GameState、存档、离线、安全区或 Android 设备验证时。

## 职责

- Godot 4.7.1、GDScript、Mobile renderer、2D 和手机端优先；持久状态只保存稳定 ID 与实例字段。
- pause/resume/heartbeat 统一走 sealed internal durable command。
- `offline_anchor_unix` 是唯一离线收益起点；回拨为 0，前跳封顶 8 小时。
- Godot M0 已有 `SafeAreaContainer` 与 `PlatformMetrics`；安全区、返回键、至少 48 基准像素的主要触控目标和 pause/resume 行为仍须通过真机门禁。

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

Godot M0 headless 与 GUT 基线已通过，但不证明真机生命周期。后续补 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、Safe Area golden、三档 Android 真机。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

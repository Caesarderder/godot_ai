---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - plan-review-only
tags:
  - domain:platform-persistence
  - risk:mobile-lifecycle
  - risk:save-consistency
related:
  - reference.state-command-lifecycle
  - reference.verification-matrix
---

# 移动平台与持久化领域

> 当前是批准设计，实际 Godot 配置、Autoload、存档和 Android 包尚未存在。

## 目标

在 Android 生命周期、杀进程和重复恢复下保持存档、离线收益和随机价值一致。

## 什么时候读

实现项目配置、Autoload、SaveManager、AppLifecycle、离线、Safe Area、Android 导出或设备验证时。

## 职责

- Godot 4.7.1 stable、GDScript-first、2D、Mobile renderer，Android-first。
- 静态定义为只读 Resource；`GameState` 使用 versioned JSON 保存稳定 ID 与实例字段。
- pause/resume/heartbeat 统一走 sealed internal durable command。
- `offline_anchor_unix` 是唯一离线收益起点；回拨为 0，前跳封顶 8 小时。
- UI 采用 Container、Safe Area，关键触控目标至少 48dp。

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、Safe Area golden、三档 Android 真机。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

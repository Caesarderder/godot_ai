---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
<<<<<<< HEAD
last_verified: 2026-07-24
=======
last_verified: 2026-07-23
>>>>>>> origin/codex/toilet-man-3d-idle
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
<<<<<<< HEAD
  - project-a/game/scripts/persistence/save_codec.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/game/scripts/autoloads/game.gd
  - project-a/tools/run_meta_tests.gd
validated_by:
  - user-confirmation-2026-07-23
  - godot --headless --path project-a -s tools/run_meta_tests.gd
=======
  - project-a/game/scripts/autoloads/save_manager.gd
  - project-a/game/scripts/autoloads/app_lifecycle.gd
  - taptap/scripts/game/GameState.lua
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - maker_build_current_directory
  - code-review
>>>>>>> origin/codex/toilet-man-3d-idle
tags:
  - domain:platform-persistence
  - risk:web-lifecycle
  - risk:save-consistency
related:
  - reference.state-command-lifecycle
  - reference.verification-matrix
---

# Web 平台与持久化领域

<<<<<<< HEAD
> 目标是手机浏览器中的 Web/PWA 运行。当前本地持久化、v2 迁移、durable command、Web release 导出和本地 HTTP 浏览器交互证据已实现；浏览器持久性探测、WebLifecycle、离线结算、PWA 与 Android/iOS 真机证据尚未实现，因此保持 `draft`。
=======
> 当前 Godot 工程已有 M0 `SaveManager`、`AppLifecycle`、Safe Area 和移动 shell，但 durable command、离线收益、备份恢复和 Android 设备证据尚未落地。TapTap 参考原型已有本地 JSON、`clientCloud` 和 8 小时离线收益，但不能作为 Godot 完成证据，因此本领域仍为 `draft`。
>>>>>>> origin/codex/toilet-man-3d-idle

## 目标

在浏览器刷新、关闭、前后台切换、隐私模式和 PWA 缓存更新下保持存档、离线收益和随机价值一致。

## 什么时候读

<<<<<<< HEAD
实现 WebLifecycle、GameState、本地存档、离线、安全区、PWA 或移动浏览器验证时。

## 职责

- Godot Web、3D、手机浏览器优先；已实现的 `GameState` 使用 `user://save_v1.json` 文件名保存 schema 3、稳定 ID、工厂和实例字段，并执行严格字段、类型和枚举校验。
- 已实现 candidate 写入、读取回验、主档/备份恢复、启动加载、新档首次持久化，以及损坏存档阻断命令的 bootstrap gate；保存失败不能交换 live state。
- visibility/resume/heartbeat 统一走 sealed internal durable command 是后续目标；浏览器后台暂停时不得依赖 Tick。
- `offline_anchor_unix` 已进入状态 schema；以它为唯一离线收益起点、回拨为 0、前跳封顶 8 小时的结算逻辑尚未实现。
- 启动检查 `OS.is_userfs_persistent()`、不可持久告警和手动导出/导入存档尚未实现。
- PWA 资源缓存不等于玩家存档；音频必须由首次点击/触摸手势解锁。
- UI 适配 viewport、安全区和 DPI；主要触控目标至少 48 基准像素。
=======
实现 Godot 移动生命周期、GameState、存档、离线、安全区或 Android 设备验证时。

## 职责

- Godot 4.7.1、GDScript、Mobile renderer、2D 和手机端优先；持久状态只保存稳定 ID 与实例字段。
- pause/resume/heartbeat 统一走 sealed internal durable command。
- `offline_anchor_unix` 是唯一离线收益起点；回拨为 0，前跳封顶 8 小时。
- Godot M0 已有 `SafeAreaContainer` 与 `PlatformMetrics`；安全区、返回键、至少 48 基准像素的主要触控目标和 pause/resume 行为仍须通过真机门禁。
>>>>>>> origin/codex/toilet-man-3d-idle

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

<<<<<<< HEAD
当前 `tools/run_meta_tests.gd` 已验证严格 JSON、v1->v2 迁移、保存失败、主档/备份恢复、既有存档加载、新档保存和损坏存档 gate。后续补刷新/关闭 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、IndexedDB 禁用、Safe Area golden、Chrome Android 与 Safari iOS 真机证据。
=======
Godot M0 headless 与 GUT 基线已通过，但不证明真机生命周期。后续补 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、Safe Area golden、三档 Android 真机。
>>>>>>> origin/codex/toilet-man-3d-idle

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

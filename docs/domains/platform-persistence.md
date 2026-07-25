---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: draft
owner: platform
last_verified: 2026-07-25
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/game/scripts/persistence/save_codec.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/game/scripts/autoloads/game.gd
  - project-a/game/scripts/platform/settings_store.gd
  - project-a/game/scripts/platform/web_runtime.gd
  - project-a/export_presets.cfg
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_platform_tests.gd
validated_by:
  - user-confirmation-2026-07-23
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_platform_tests.gd
tags:
  - domain:platform-persistence
  - risk:web-lifecycle
  - risk:save-consistency
related:
  - reference.state-command-lifecycle
  - reference.verification-matrix
---

# Web 平台与持久化领域

> 目标是手机浏览器中的 Web/PWA 运行。当前游戏存档、设置存档、Web 焦点/可见性处理、单线程 Web 导出、PWA 元数据和本地产物审计已实现；生产源持久性、离线结算、Android/iOS 真机与部署证据仍未关闭，因此保持 `draft`。

## 目标

在浏览器刷新、关闭、前后台切换、隐私模式和 PWA 缓存更新下保持存档、离线收益和随机价值一致。

## 什么时候读

实现 WebLifecycle、GameState、本地存档、离线、安全区、PWA 或移动浏览器验证时。

## 职责

- Godot Web、3D、手机浏览器优先；已实现的 `GameState` 使用 `user://save_v1.json` 文件名保存 schema 4、内容版本 `factory-siege-v4`、稳定 ID、工厂、任务、成就和实例字段，并执行严格字段、类型和枚举校验。
- 已实现 candidate 写入、读取回验、主档/备份恢复、启动加载、新档首次持久化，以及损坏存档阻断命令的 bootstrap gate；保存失败不能交换 live state。
- `SettingsStore` 独立保存音量、特效质量、减少动态和全局自动技能；坏配置回退默认值，全局自动技能默认关闭。
- `WebRuntime` 暴露平台能力、焦点与页面可见性；战斗失焦/隐藏后暂停并要求玩家主动继续，浏览器后台不得依赖 Tick。
- `offline_anchor_unix` 已进入状态 schema；以它为唯一离线收益起点、回拨为 0、前跳封顶 8 小时的结算逻辑尚未实现。
- PWA 元数据、离线 fallback、图标与 service worker 构建已配置；PWA 资源缓存不等于玩家存档。
- 启动检查 `OS.is_userfs_persistent()`、不可持久告警、手动导出/导入存档和生产源音频解锁验证尚未完成。
- UI 适配 viewport、安全区和 DPI；主要触控目标至少 48 基准像素。

## 不是本层职责

不决定英雄数值、装备词条或关卡平衡。

## 不变量

后台不依赖持续运行；UI 不直接写状态；保存失败不能报告价值操作成功。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)。

## 验证

`run_meta_tests.gd` 验证严格 JSON、迁移、保存失败、主备恢复和损坏存档 gate；`run_platform_tests.gd` 验证设置默认值/往返/坏档回退/归一化及焦点信号。后续补生产 HTTPS 上的刷新/关闭 crash matrix、20m 前台+5m 后台、重复 resume、回拨/48h 跳时、IndexedDB 禁用、Safe Area golden、Chrome Android 与 Safari iOS 真机证据。

## 相关节点

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

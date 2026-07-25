---
km_id: decision.project-a-web-3d-root
km_type: decision
domain: architecture
status: active
owner: maintainers
last_verified: 2026-07-24
source_of_truth:
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - user-confirmation-2026-07-23
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
tags:
  - decision:project-root
  - decision:web-first
  - decision:3d-presentation
related:
  - decision.durable-domain-kernel
  - decision.taptap-maker-game-root
  - reference.architecture-overview
  - reference.file-ownership
  - invariant.project-boundaries
---

# ADR-0005：以 project-a 承载 Web-first 3D 游戏

## 状态

Accepted，2026-07-23；取代 [KM:decision.taptap-maker-game-root](ADR-0004-taptap-maker-game-root.md) 作为当前实现根决策。

## 决策

- 当前游戏实现根为 `project-a/`，引擎锁定 Godot 4.6.3，语言使用纯 GDScript。
- 游戏采用 3D 表现，首发运行形态是 Web，主要目标设备是手机浏览器；不是 Android/iOS 原生包优先。
- Web 构建使用 Compatibility renderer / WebGL 2.0。默认单线程导出，只有确有性能证据且托管端能保证跨源隔离时才评估多线程。
- 发布形态优先 PWA、HTTPS 和可添加到主屏幕；PWA 缓存是启动优化，不是存档备份。
- 保留 [KM:decision.durable-domain-kernel](ADR-0002-durable-domain-kernel.md)：纯 GDScript 领域内核拥有状态、命令、战斗、任务、离线和持久化语义；`Node3D`、`Control`、动画和 VFX 只是投影。
- `taptap/` 保留为历史原型和产品参考，不再是默认实现根，不再使用 Maker 工作流交付当前版本。

## 原因

- 用户明确要求 Godot 4.6.3、3D，并要求游戏支持 Web、主要在手机端浏览器运行。
- Godot 4 Web 导出只支持 Compatibility/WebGL 2.0；Forward+ 和 Mobile renderer 不能作为 Web 运行后端。
- 浏览器会暂停后台标签页，且浏览器存储可能因隐私模式、用户设置或空间回收而不可持久，因此放置结算和存档必须有显式平台边界。
- 产品最重要的验证仍是工厂生产、永久培育、六人编队、失败后成长再胜；不应让 3D 场景树或浏览器生命周期成为领域真值。

## 影响

- `project-a/project.godot` 已切换 Compatibility，`project-a/export_presets.cfg` 已提供单线程 Web preset，release 构建可生成 `index.html/.pck/.wasm`；这只完成 Web 导出基线，不代表 PWA、平台生命周期或真机门禁通过。
- 玩家存档使用版本化 JSON 写入 `user://`。Web 上该路径映射到浏览器存储；启动时必须检查 `OS.is_userfs_persistent()`，不可持久时显示阻断性警告。
- 后台期间不运行战斗 Tick；恢复时只按 `offline_anchor_unix` 执行幂等离线结算。
- 3D 战斗采用固定 2 前排 + 2 后排槽位。物理、导航、动画、碰撞检测不得决定命中、目标、伤害或胜负。
- 屏幕方向、战斗镜头和最终美术预算仍需确认；它们不得改变领域内核接口。

## 落实状态

2026-07-24 校准：上方“影响”保留为决策当时的历史原文，不回写其时态。当前工程已从 Forward+ 切换到 GL Compatibility；当前切片已实现 `GameState` schema 3、8 英雄、L1-L5 培养、三材料八配方工厂、3 队列、生产领取、同原型同星 3 合 1、六槽编队、经济资源、命令 fingerprint/幂等/revision/先存后换、严格 JSON、v1->v2->v3 迁移、主档/备份恢复、bootstrap gate 和三阶段 5Hz 战斗，并通过 `tools/run_meta_tests.gd` 与 `tools/run_battle_tests.gd`。

Web/PWA export preset、离线页/图标/service worker、本地产物审计、设置存储、失焦暂停与 844×390 本地 HTTP 浏览器路径已落实；生产源持久性探测、音频解锁、离线结算、装备、任务、跨帧率 digest、paired balance 和手机浏览器真机证据尚未落实，因此 M0-M5 仍不能据此标记整体通过。

## 相关节点

[KM:reference.architecture-overview](../references/architecture/architecture-overview.md)。

[KM:reference.file-ownership](../references/indexes/file-ownership.md)。

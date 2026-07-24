---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
<<<<<<< HEAD
last_verified: 2026-07-24
=======
last_verified: 2026-07-23
>>>>>>> origin/codex/toilet-man-3d-idle
source_of_truth:
  - README.md
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - visual-capture-1920x1080-and-844x390
tags:
  - reference:implementation-status
  - risk:planned-not-implemented
related:
  - reference.file-ownership
  - quality.stale-docs
  - decision.return-to-project-a
---

# 实现状态基线

## 目标

防止知识地图把批准规划误写成已经实现的系统。

## 事实

<<<<<<< HEAD
- 当前开发根是 `project-a/`，使用 Godot 4.6.3、GDScript 和 3D 表现，目标为 Web-first、手机浏览器优先。
- 项目已切换到 Compatibility renderer；主场景现为长期存在的 App Shell，承载标题、营地、工厂、培育、六人编队、出征确认、战斗 HUD、技能按钮、自动技能开关与结算 UI。
- v3 Meta 领域内核已落地：可序列化 `GameState` schema 3、固定 seed 初始 8 英雄、四职业/八原型/四资质/特质、星级、L1-L5 培养、六槽编队、经济资源、工厂材料、蓝图锁定/解锁、生产队列、自动技能偏好、命令 fingerprint/幂等/revision/先存后换、严格 JSON schema、v1/v2->v3 迁移、主档/备份恢复和启动加载。
- 新档基线为 8 名英雄、有效六槽编队、250 金币、2 本经验书、120 瓷、100 零件和 80 污泥；英雄、编队、培养、工厂、合成、命令与存档契约由 `project-a/tools/run_meta_tests.gd` headless 验证。
- v3 可玩切片已落地：标题进入、营地、四车间工厂、八配方生产/锁定预览、订单倒计时与离线到期领取、同原型同星 3 合 1、训练 UI、六人编队、三阶段出征确认、六名程序化低模马桶人推进并摧毁联盟基地、核心巨炮、技能 HUD、胜负结算、重试和返回营地。
- 战斗领域以 5Hz 固定 tick 运行，自动推进、联盟普通守军/精英、结构目标、八原型 canonical 技能、星级技能质变、核心炮预警/命中、阶段切换、超时和结果只依赖纯 GDScript `BattleSession`；`BattleWorld` 与 `ToiletUnitView` 只投影快照和事件。`settle_battle` 以 `battle_id` business key 幂等写入金币、经验书、三材料奖励、首败/超时反攻蓝图、失败/超时残骸、关卡完成和尝试次数。
- 当前 UI 使用容器、全屏锚点和横屏安全边距，并嵌入 Noto Sans CJK SC 以避免 Web 中文缺字。1920×1080、844×390 Compatibility 截图，以及 844×390 本地 HTTP Web 构建的标题、营地、工厂生产/领取、培育、编队、出征、战斗和失败结算均已人工检查；浏览器控制台无 error/warn。该证据不等于 Chrome Android/Safari iOS 真机通过。
- `project-a/export_presets.cfg` 已提供单线程 Web release preset，本机已安装 Godot 4.6.3 Web 模板并成功生成 `project-a/build/web/index.html`、`.pck` 与 `.wasm`。生产订单已支持绝对时间离线到期与一次性领取；尚不存在：PWA、浏览器持久性探测、音频解锁、完整装备玩法、任务 reducer、离线战斗收益、Web 真机证据、跨帧率 digest 和 paired 1000 平衡门禁。
- `taptap/` 的 UrhoX Lua 2D 版本保留为历史可玩原型；它的实现和远端构建证据不能用于宣称当前 Godot Web 版本已完成。
- 已落地的 `project-a` shell、`game/scripts/{state,commands,domain,persistence,autoloads}/**` 与 `tools/run_meta_tests.gd` 可使用 `CODE:*` 标签；其余规划路径禁止在存在前标记为代码事实。

## 入口或路径

[CODE:project-config](../../../project-a/project.godot)、[CODE:main-scene](../../../project-a/scenes/screens/main.tscn)、[CODE:app-shell](../../../project-a/scripts/main.gd)、[CODE:factory-catalog](../../../project-a/game/scripts/domain/factory/factory_catalog.gd)、[CODE:factory-service](../../../project-a/game/scripts/domain/factory/factory_service.gd)、[CODE:battle-session](../../../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:battle-world](../../../project-a/game/scripts/presentation_3d/battle_world.gd)、[CODE:meta-tests](../../../project-a/tools/run_meta_tests.gd)、[CODE:battle-tests](../../../project-a/tools/run_battle_tests.gd)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

当前已验证 Godot 4.6.3 headless 导入、主场景启动、Compatibility 配置、Meta/战斗/完整生命周期测试、Web release export，以及桌面与本地 HTTP 手机横屏浏览器渲染交互。PWA、Chrome Android/Safari iOS 真机、跨帧率 digest、paired balance、装备、任务和离线门禁必须在对应里程碑落地后重新验证。
=======
- 当前开发根是 `project-a/` Godot 4.7.1 Mobile 工程；玩法、UI、测试与后续构建默认在此落地。
- `project-a/` 的 Godot M0 已通过 GUT 10/10、34 asserts 和三条 headless 启动链；它是当前开发基线，但尚不是完整可玩版本。
- 尚不存在：随机英雄运行实例、四槽编队、装备实例/随机词条、任务 reducer、三设施薄营地、1000-seed 经济/战斗门禁和 Android 设备证据。
- `project-a/addons/godot_ai/**` 是现有智能体工具插件并含用户工作树改动；它属于目标工程的工具层，不是游戏领域代码，默认不得被游戏任务修改/格式化/清理。
- `taptap/` 原型已实现 30 关自动战斗、三名固定队员培养、三项锻造升级、主动技能、本地/云存档和最多 8 小时离线收益，并有提交 `cd5fa47` 的远端构建记录；这些仅是参考原型事实，不等于 Godot 已完成对应功能。
- 已落地的 Godot 与 TapTap 参考路径可使用 `CODE:*` 标签；未来 Godot 领域路径仍是规划落点，禁止在存在前标记为代码事实。

## 入口或路径

[CODE:godot-project](../../../project-a/project.godot)、[CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)、[CODE:taptap-entry](../../../taptap/scripts/main.lua)、[CODE:taptap-state](../../../taptap/scripts/game/GameState.lua)、[CODE:taptap-ui](../../../taptap/scripts/ui/GameUI.lua)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

Godot 当前基线使用 `GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh` 回归；后续 milestone 追加对应 GUT、headless、模拟与 Android 设备证据。只有维护 `taptap/` 参考原型时才使用 `maker_status_lite` 和 `maker_build_current_directory`。
>>>>>>> origin/codex/toilet-man-3d-idle

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

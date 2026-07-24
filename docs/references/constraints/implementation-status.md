---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - README.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/verify_m0.sh
  - taptap/scripts/main.lua
  - taptap/scripts/game/GameState.lua
  - taptap/scripts/ui/GameUI.lua
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - protected-addon-hash-audit
  - maker_status_lite
  - maker_build_current_directory
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

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

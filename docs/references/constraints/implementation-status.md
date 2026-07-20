---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-20
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
---

# 实现状态基线

## 目标

防止知识地图把批准规划误写成已经实现的系统。

## 事实

- 当前开发根是 `taptap/` 绑定 Maker 工程，使用 UrhoX Lua、`urhox-libs/UI` 和纯 2D 表现；首次迁移提交 `cd5fa47` 已通过 TapTap MCP 远端构建与预览刷新。
- 当前原型已实现 30 关自动战斗、三名固定队员培养、三项锻造升级、主动技能、本地/云存档和最多 8 小时离线收益；这些是迁移基线，不等于批准规划中的随机英雄、四槽编队和随机装备已经完成。
- 尚不存在：随机英雄运行实例、四槽编队、装备实例/随机词条、任务 reducer、三设施薄营地、1000-seed 经济/战斗门禁和 Android 设备证据。
- `project-a/` 的 Godot 4.7.1 M0 仍完整保留并通过 GUT 10/10、34 asserts 和三条 headless 启动链，但它是历史基线，不再是默认玩法落点。
- `project-a/addons/godot_ai/**` 是现有智能体工具插件并含用户工作树改动；它属于目标工程的工具层，不是游戏领域代码，默认不得被游戏任务修改/格式化/清理。
- 已落地的 TapTap 与 Godot 历史路径可使用 `CODE:*` 标签；未来领域路径仍是规划落点，禁止在存在前标记为代码事实。

## 入口或路径

[CODE:taptap-entry](../../../taptap/scripts/main.lua)、[CODE:taptap-state](../../../taptap/scripts/game/GameState.lua)、[CODE:taptap-ui](../../../taptap/scripts/ui/GameUI.lua)、[CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

TapTap 开发先读 `maker_status_lite`，本地检查后用 `maker_build_current_directory` 提交并远端构建；首次迁移构建为 100% 成功。Godot 历史基线继续用 `GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh` 回归。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-21
source_of_truth:
  - README.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/verify_m0.sh
  - project-a/game
  - project-a/tests
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - protected-addon-hash-audit
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

- 当前开发根是 `project-a/` Godot 4.7.1 Mobile 工程，使用 GDScript、纯 2D、Mobile renderer 与 GUT；M1-M5 规划和实现只落在这里。
- Godot M0 基线已通过 GUT 10/10、34 asserts 和三条 headless 启动链。工作树中已经出现 M1-M3 相关代码与测试路径，但其完成度必须由对应里程碑验证器确认，不能仅凭文件存在宣称通过。
- 装备实例/随机词条、任务 reducer、三设施薄营地、完整 1000-seed 经济/战斗门禁和 Android 设备证据仍按后续 milestone 验证。
- `taptap/` Maker 原型暂时搁置；其自动战斗、培养、锻造和存档能力不计入当前 Godot milestone 完成度。
- `project-a/addons/godot_ai/**` 是现有智能体工具插件并含用户工作树改动；它属于目标工程的工具层，不是游戏领域代码，默认不得被游戏任务修改/格式化/清理。
- 已落地的 Godot 路径可使用 `CODE:*` 标签；未来路径在存在并验证前只能标为规划落点。暂停的 TapTap 路径不得作为当前实现事实。

## 入口或路径

[CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)、`project-a/project.godot`、`project-a/game/**`、`project-a/tests/**`、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

Godot 基线使用 `GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh` 回归；M1-M5 使用各自 Godot/GUT 验证器和测试规格中的 headless 命令。TapTap MCP 构建只保留历史证据。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - README.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/verify_m0.sh
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

- M0 已存在并通过 headless 验证：Godot 4.7.1 Mobile 工程、1080x1920 portrait shell、Safe Area、六个游戏 Autoload、GUT v9.7.1、M0 unit/integration tests 与 `project-a/tools/verify_m0.sh`。
- M0 仅建立薄外壳：`SaveManager` 只暴露保存请求契约，不含 M1 存档格式、备份、离线结算或 command lifecycle。
- 尚不存在：M1-M5 英雄/编队/战斗/装备/任务/营地玩法实现、Resources 定义、Android 导出配置和设备证据。
- `project-a/addons/godot_ai/**` 是现有智能体工具插件并含用户工作树改动；它属于目标工程的工具层，不是游戏领域代码，默认不得被游戏任务修改/格式化/清理。
- 已落地的 M0 路径可使用 `CODE:*` 标签；未来领域路径仍是规划落点，禁止在存在前标记为代码事实。

## 入口或路径

[CODE:project-config](../../../project-a/project.godot)、[CODE:m0-verifier](../../../project-a/tools/verify_m0.sh)、[KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

每个 milestone 前后运行 baseline 与对应 verifier，并检查 `project-a/project.godot`、`rg --files project-a/game project-a/tests project-a/tools` 和受保护 addon；M0 当前结果为 GUT 10/10 tests、34 asserts、三条 headless 启动链通过。首次 baseline 的逐文件 untracked hash 缺口已在 `.omx/evidence/m0/pre-m0-observed.md` 如实记录，增强后的 post-M0 baseline 作为后续 milestone 冻结点。

## 相关节点

[KM:quality.stale-docs](../../quality/stale-docs.md)。

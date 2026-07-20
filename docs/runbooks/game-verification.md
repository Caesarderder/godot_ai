---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/tools/verify_m0.sh
  - taptap/.maker-mcp/config.json
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - maker_status_lite
  - maker_build_current_directory
tags:
  - quality:game-verification
  - risk:planned-not-implemented
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> TapTap 迁移基线已完成远端构建；M1-M5 内容、模拟和 Android 设备命令尚未全部落地，因此本节点整体保持 `draft`。

## 目标

在 M0-M5 分阶段验证 TapTap Maker 项目、内容、经济、战斗和 Android 设备，同时保留 Godot M0 历史回归。

## 前置条件

当前目录存在 `taptap/.maker-mcp/config.json`，TapTap MCP 鉴权、Maker 绑定和 AI dev kit 就绪。执行 Maker 提交/构建前先读取状态，不手工提交绑定工程。

## game-verification

当前 Maker 工程通过 MCP 工具调用，不是 shell 命令：

```text
maker_status_lite
  target_dir: /absolute/path/to/taptap

maker_build_current_directory
  target_dir: /absolute/path/to/taptap
  entry: main.lua
  scriptsPath: scripts
```

历史 Godot M0 与未来本地验证命令才在 shell 执行：

```bash
GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh

# M1-M5 待对应实现落地后启用
taptap/tools/validate_content.lua
taptap/tools/simulate_first_30m.lua --manifest=taptap/tests/fixtures/battle/paired_1000_v1.json
```

Android build/install/launch 命令以测试规格 §11 为准，必须限时收集 logcat，不能无限等待。

## 预期结果

当前 Maker 预期为项目同步、提交推送、远端构建和 preview refresh 全部成功；运行问题读取 MCP 返回的 `runtime_logs.local_file`。历史 Godot M0 仍预期 GUT 10/10 与三条 headless 启动链通过。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

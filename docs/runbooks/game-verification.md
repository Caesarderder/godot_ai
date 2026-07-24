---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-23
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

> Godot M0 已完成本地验证；M1-M5 内容、模拟和 Android 设备命令尚未全部落地，因此本节点整体保持 `draft`。TapTap 远端构建只保留为参考原型证据。

## 目标

在 M0-M5 分阶段验证 `project-a/` Godot 项目、内容、经济、战斗和 Android 设备；TapTap Maker 原型只在明确维护时单独验证。

## 前置条件

本机存在 Godot 4.7.1，当前工程路径为 `project-a/`，受保护的 `godot_ai` 与 GUT 插件保持可用。运行前先确认工作树，不覆盖 `project-a/project.godot`、插件或用户未提交改动。

## game-verification

```bash
GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh

# M1-M5 待对应实现落地后启用
GODOT_BIN=/opt/homebrew/bin/godot
"$GODOT_BIN" --headless --path project-a -s tools/validate_content.gd
"$GODOT_BIN" --headless --path project-a -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

上述 M1-M5 命令是规划落点，脚本存在前不得执行或宣称通过。Android build/install/launch 命令以测试规格 §11 为准，必须限时收集 logcat，不能无限等待。

只有明确维护 `taptap/` 参考原型时才通过 TapTap MCP 调用 `maker_status_lite` 与 `maker_build_current_directory`，且不得把结果计入 Godot milestone。

## 预期结果

当前 Godot M0 预期 GUT 10/10 与三条 headless 启动链通过。后续 milestone 必须满足对应自动测试、模拟、Android 设备与真人观察门槛；TapTap 参考原型通过与否不替代这些证据。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

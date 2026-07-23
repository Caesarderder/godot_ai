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
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
tags:
  - quality:game-verification
  - risk:planned-not-implemented
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> Godot M0 基线已通过；M1-M5 的验证器、模拟和 Android 设备证据随里程碑推进，因此本节点整体保持 `draft`。

## 目标

在 M0-M5 分阶段验证 `project-a/` Godot 项目、内容、经济、战斗和 Android 设备。

## 前置条件

准备 Godot 4.7.1、GUT 9.7.1 和对应平台依赖。所有命令从仓库根运行；先检查工作树并保护 `project-a/addons/godot_ai/**`。

## game-verification

Godot 验证命令：

```bash
GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh

# M1-M5 待对应实现落地后启用
godot --headless --path project-a -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --path project-a -s tools/validate_content.gd
godot --headless --path project-a -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

Android build/install/launch 命令以测试规格 §11 为准，必须限时收集 logcat，不能无限等待。

## 预期结果

M0 预期 GUT 10/10 与三条 headless 启动链通过；后续 milestone 必须满足验证矩阵中的 focused、full-suite、模拟和设备门槛。暂停的 TapTap 构建结果不计入退出条件。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

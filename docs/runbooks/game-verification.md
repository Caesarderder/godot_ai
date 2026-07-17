---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-17
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

> M0 游戏 shell/GUT 已就绪并实际运行；M1-M5 内容、模拟和 Android 命令尚未全部落地，因此本节点整体保持 `draft`。

## 目标

在 M0-M5 分阶段验证 Godot 项目、内容、经济、战斗和 Android 设备。

## 前置条件

存在 `project-a/project.godot`、锁定 GUT 版本/许可/checksum、Godot 4.7.1 和相应 Android SDK/JDK/export templates；现有 godot_ai plugin/autoload 保持启用。

## game-verification

```bash
godot --version
GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh

# 等价的 M0 GUT 核心命令
godot --headless -d --path project-a -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# M1-M5 待对应实现落地后启用
godot --headless --path project-a -s tools/validate_content.gd
godot --headless --path project-a -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

Android build/install/launch 命令以测试规格 §11 为准，必须限时收集 logcat，不能无限等待。

## 预期结果

M0 预期为三条 headless 启动链和全部 GUT 测试通过；后续 milestone 对应 [KM:reference.verification-matrix](../references/indexes/verification-matrix.md) 全部通过。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

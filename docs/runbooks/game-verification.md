---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - plan-review-only
tags:
  - quality:game-verification
  - risk:planned-not-implemented
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> `game/` 尚不存在，以下命令来自批准测试规格但均未在本仓库成功运行。本节点保持 `draft`。

## 目标

在 M0-M5 分阶段验证 Godot 项目、内容、经济、战斗和 Android 设备。

## 前置条件

存在 `game/project.godot`、锁定 GUT 版本/许可/checksum、Godot 4.7.1 和相应 Android SDK/JDK/export templates。

## game-verification

```bash
godot --version
godot --headless --path game --editor --quit
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --path game -s tools/validate_content.gd
godot --headless --path game -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

Android build/install/launch 命令以测试规格 §11 为准，必须限时收集 logcat，不能无限等待。

## 预期结果

每个 milestone 对应 [KM:reference.verification-matrix](../references/indexes/verification-matrix.md) 全部通过。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/tools/verify_m0.sh
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - runbook.game-verification
---

# 验证矩阵

## 目标

把批准的 Godot milestone 退出条件路由到证据；M0 已通过，M1-M5 必须由 `project-a/` 的实现、GUT/headless、模拟与设备证据关闭。

## 事实

| Milestone | 证据 |
|---|---|
| M0（PASS；当前 Godot baseline） | GUT v9.7.1 10/10 tests、34 asserts；editor/mobile/compatibility headless shell 通过；plugin/autoload 共存；245 个 godot_ai 文件仅 R100 移动、0 内容差异；首次逐文件 untracked hash 缺失不可逆，已增强工具并冻结 post-M0 baseline |
| M1 | command classification/fingerprint、internal lifecycle、crash matrix、20m+5m、600 replay、backup |
| M2 | L1-L5 clamp/growth golden、固定 seed 8 heroes、formation、可读性观察 |
| M3 | stable hash/tie-break、跨 FPS、1-1/1-2/1-3 绝对区间和 1-3 paired +30pp |
| M4 | 经济 ledger、pity、claim once、soft quest、facility、1-4/1-5 区间和 1-5 paired +30pp |
| M5 | 全部 headless、三档 Android、P01-P05、最终 scope/hash audit |
| 当前 docs init | [CMD:docs-lint](../../runbooks/docs-lint.md#docs-lint) 零错误 |

技术自动/设备门槛为 100%；真人观察关键项各 >=4/5，总计 >=45/50。实现者不能自批，独立 verifier 保存原始输出、设备日志和 manifest hash。

## 入口或路径

[CODE:test-spec](../../../.omx/plans/test-spec-fantasy-idle-expedition.md)。

## 验证

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；Godot M0 已验证，M1-M5 在对应实现、测试和证据真正运行前保持未验证。TapTap 历史构建不属于本矩阵 gate。

## 相关节点

[KM:workflow.code-writing-review](../../workflows/code-writing-review.md)。

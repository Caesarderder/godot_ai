---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/tools/verify_m0.sh
  - taptap/.maker-mcp/config.json
validated_by:
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - maker_build_current_directory
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - runbook.game-verification
---

# 验证矩阵

## 目标

把批准的 milestone 退出条件路由到证据；Godot 当前 M0 和 TapTap 参考原型基线已通过，M1-M5 必须以 Godot 实现证据关闭。

## 事实

| Milestone | 证据 |
|---|---|
| Godot M0（当前基线 PASS；历史 baseline 例外已记录） | GUT v9.7.1 10/10 tests、34 asserts；editor/mobile/compatibility headless shell 通过；plugin/autoload 共存；245 个 godot_ai 文件仅 R100 移动、0 内容差异；首次逐文件 untracked hash 缺失不可逆，已增强工具并冻结 post-M0 baseline |
| TapTap 参考原型（PASS，不关闭 Godot milestone） | Maker 项目已绑定且远端同步；UrhoX Lua 2D 原型存在；`maker_build_current_directory` 提交 `cd5fa47`、远端构建 100%、preview refresh 200、runtime watcher 启动 |
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

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；Godot M0 与 TapTap 参考构建均有历史证据，但后续 M1-M5 只由 Godot 代码、测试、模拟和设备证据关闭。

## 相关节点

[KM:workflow.code-writing-review](../../workflows/code-writing-review.md)。

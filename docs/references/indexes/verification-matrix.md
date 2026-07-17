---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - critic-plan-approval
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - runbook.game-verification
---

# 验证矩阵

## 目标

把批准的 milestone 退出条件路由到证据；当前除 docs lint 外均是待实现 gate，不代表已经通过。

## 事实

| Milestone | 证据 |
|---|---|
| M0 | dirty baseline、批准路径 `project-a/addons/gut/**` 的 GUT gate、project-a headless shell、现有 plugin/autoload 与新增游戏 Autoload 共存、受保护 godot_ai addon 不变 |
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

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；命令在 project-a 游戏 shell 落地前保持未验证。

## 相关节点

[KM:workflow.code-writing-review](../../workflows/code-writing-review.md)。

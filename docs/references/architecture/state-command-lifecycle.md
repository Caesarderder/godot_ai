---
km_id: reference.state-command-lifecycle
km_type: reference
domain: architecture
status: draft
owner: platform
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - architect-plan-approval
  - critic-plan-approval
tags:
  - reference:state-command-lifecycle
  - risk:exact-once
related:
  - domain.platform-persistence
  - decision.durable-domain-kernel
  - reference.verification-matrix
---

# 状态、命令与生命周期契约

> 以下是执行契约，不代表相关脚本已经存在。

## 目标

保证价值操作、任务进度、离线收益在单设备、单 writer、应用 crash/Android kill 范围内只产生一次效果。

## 事实

### 状态边界

- `GameState`：roster、inventory、formation、economy、camp、quest、pity、stage、attempt、receipt 和四时间字段。
- `BattleSession/BattleState`：当前战斗的 seed、tick、单位状态、局部 RNG、表现队列；不进入存档。
- `BattleResult`：战斗完成后的不可变结算输入；手动退出无奖励。

### 命令分类

- `DURABLE_VALUE`：招募、训练、强化、设施升级、领奖、战斗/离线结算、attempt reservation。
- `INTERNAL_DURABLE`：pause anchor、foreground heartbeat、resume/offline settlement。
- `REVERSIBLE_META`：编队、装备、筛选、重命名，可 debounce。
- `EPHEMERAL`：导航、动画、临时 tick，不进入 GameState/receipt。

所有耐久操作遵循 candidate clone -> reducer/QuestReducer -> receipt -> durable save -> memory swap -> success。调用方不得降低 durability 或绕过 executor。

### 时间字段

- `saved_at_unix`：成功提交快照中记录的写入尝试时间，仅审计。
- `last_seen_wall_unix`：单调诊断上界。
- `last_settled_unix`：最近一次成功离线结算时间，仅审计。
- `offline_anchor_unix`：唯一离线 accrual 起点。

### Receipt

命令 ID 绑定 canonical fingerprint；同 ID 不同 payload/business key 必须 hard error。价值 receipt 保留整个存档期，任务 causal receipt 保留到所有消费者 terminal+claimed。

## 入口或路径

计划实现路径见 [KM:reference.file-ownership](../indexes/file-ownership.md)。

## 验证

classification/fingerprint golden、600 replay、crash matrix、20m+5m、重复 resume、rollback/48h jump。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。

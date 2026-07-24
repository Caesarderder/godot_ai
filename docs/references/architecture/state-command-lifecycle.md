---
km_id: reference.state-command-lifecycle
km_type: reference
domain: architecture
status: draft
owner: platform
last_verified: 2026-07-24
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/commands/command_fingerprint.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/game/scripts/autoloads/game.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - independent-code-review-2026-07-23
tags:
  - reference:state-command-lifecycle
  - risk:exact-once
related:
  - domain.platform-persistence
  - decision.durable-domain-kernel
  - reference.verification-matrix
---

# 状态、命令与生命周期契约

> 当前已实现本页的 GameState schema 3、公开耐久命令、fingerprint、幂等、revision、先存后换、严格 JSON、v1->v2->v3 迁移、主备恢复和 bootstrap gate；战斗已实现临时三阶段 BattleSession、BattleResult 与一次性战斗结算。WebLifecycle、离线结算、装备和任务链仍是目标契约，因此节点保持 `draft`。

## 目标

保证价值操作、任务进度、离线收益在单设备、单 writer、应用 crash/Android kill 范围内只产生一次效果。

## 事实

### 状态边界

- `GameState`：已实现 schema 3、content version `factory-siege-v3`、roster、inventory、六槽 formation、economy、factory、camp、quests、pity、stage_progress、attempt_counters、receipt ledgers 和四时间字段；未完成系统以严格可持久化骨架存在。
- `FactoryState`：已实现三材料、蓝图表、最多三项生产队列、生产序列和单调英雄序列。
- `BattleSession/BattleState`：已用纯 GDScript 5Hz 状态承载 tick、六人单位、七个结构目标、阶段、技能、炮击预警和表现事件；它不进入存档。跨帧率 digest 仍待实现。
- `BattleResult`：已作为战斗完成后的结算输入，并由 `settle_battle` 通过稳定 `battle_id` business key 一次性提交；手动退出无奖励。

### 命令分类

- `DURABLE_VALUE`：当前已覆盖新英雄、训练、受控资源变更、战斗结算、开始生产、领取生产和 3 合 1 合成；强化、设施升级、领奖、离线结算与 attempt reservation 待实现。
- `INTERNAL_DURABLE`：pause anchor、foreground heartbeat、resume/offline settlement 尚未实现。
- `REVERSIBLE_META`：六槽编队走立即提交；装备、筛选、重命名及 debounce 尚未实现。
- `EPHEMERAL`：导航、动画、临时 tick，不进入 GameState/receipt。

当前所有已实现命令遵循 candidate clone -> reducer -> invariants -> receipt -> durable save -> memory swap -> success；未提供保存回调、保存失败或 revision 过期时不会交换 live state。QuestReducer 尚未实现。调用方不得降低 durability 或绕过 executor。

### 时间字段

- `saved_at_unix`：成功提交快照中记录的写入尝试时间，仅审计。
- `last_seen_wall_unix`：单调诊断上界。
- `last_settled_unix`：最近一次成功离线结算时间，仅审计。
- `offline_anchor_unix`：唯一离线 accrual 起点。

### Receipt

命令 ID 绑定 canonical fingerprint；同 ID 同 fingerprint 返回原 receipt，同 ID 或 business key 复用但 fingerprint 不同会 hard error。canonical payload 只接受受控 JSON 值，公开命令校验精确字段与类型。价值 receipt 已写入存档；任务 causal receipt 的 terminal+claimed 生命周期尚未实现。

## 入口或路径

已实现路径见 [KM:reference.file-ownership](../indexes/file-ownership.md)，核心入口为 [CODE:command-executor](../../../project-a/game/scripts/commands/command_executor.gd)、[CODE:save-manager](../../../project-a/game/scripts/persistence/save_manager.gd) 和 [CODE:game-bootstrap](../../../project-a/game/scripts/autoloads/game.gd)。

## 验证

已通过 `godot --headless --path project-a -s tools/run_meta_tests.gd` 验证 fingerprint、幂等、business key 冲突、revision、保存失败、严格 schema、v1->v2 迁移、工厂/合成事务、主备恢复与 bootstrap gate。600 replay、浏览器 crash matrix、20m+5m、重复 resume、rollback/48h jump 尚未验证。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。

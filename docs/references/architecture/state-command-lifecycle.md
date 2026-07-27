---
km_id: reference.state-command-lifecycle
km_type: reference
domain: architecture
status: draft
owner: platform
last_verified: 2026-07-27
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/implementation-status.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/commands/command_fingerprint.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/quest/quest_service.gd
  - project-a/game/scripts/domain/achievement/achievement_catalog.gd
  - project-a/game/scripts/domain/achievement/achievement_service.gd
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/game/scripts/autoloads/game.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - manual-design-integrity-review-2026-07-26
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
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

> 当前已实现 `GameState` schema 11、content `toilet-factory-slg-v3-factions`、公开耐久命令、fingerprint、
> 幂等、revision、先存后换、严格 JSON、主备恢复、导入预览与 bootstrap gate。v5/v6/v7 有显式迁移；
> 旧图纸、生产队列、维修与库存字段只作兼容输入，不再拥有玩家入口或领域权威。

## 目标

保证价值操作、任务进度、离线收益在单设备、单 writer、应用 crash/Android kill 范围内只产生一次效果。

## 事实

### 状态边界

- `GameState`：schema v8 持有永久 `roster`、六槽 `formation`、`economy`、三材料与设施状态、
  `onboarding`、`meta_progression`、关卡进度、尝试次数和两类 receipt；兼容字典不得被 UI 当作新玩法真值。
- `achievements`：顶层五桶固定为 `progress`、`completed`、`claimed`、`event_keys`、`counters`。`progress/completed/claimed` 支持完成与手动领取分离；`event_keys` 使用 command_id 级别事件去重；`counters` 保存可靠回填后的单调计数。
- `FactoryState`：三材料、容量、设施等级、5×5 放置、独立产出锚、设施施工和单调永久英雄序列
  是当前权威；图纸、生产队列与维修订单字段仅保留迁移兼容。
- `BattleSession/BattleState`：目标用纯 GDScript 5Hz 承载 1–6 个实际部署单位、阶段、技能、炮击预警、生死标记和撤退请求；它不进入存档。
- `BattleResult`：包含胜利/全灭/超时/撤退、本局阵亡/存活表现、炮击统计和受控奖励，并由稳定
  `battle_id` exact-once 提交；本局阵亡不得删除或伤害永久角色。

### 命令分类

- `DURABLE_VALUE`：覆盖钱包、工厂领取/建造/升级、永久角色升级/升星/技能、研究突破、六槽编队、
  任务/战令/成就领奖、招募和无损战斗结算。
- `INTERNAL_DURABLE`：离线产出锚、周期刷新和恢复结算仍必须通过受控命令与同一 writer。
- `REVERSIBLE_META`：当前编队属于耐久价值操作并立即提交；筛选、页签和滚动位置属于 UI 状态。
- `EPHEMERAL`：导航、动画、临时 tick，不进入 GameState/receipt。

当前所有已实现命令遵循 candidate clone -> reducer -> invariants -> receipt -> durable save -> memory swap -> success；未提供保存回调、保存失败或 revision 过期时不会交换 live state。`QuestService` 与 `AchievementService` 消费成功领域事件，任务/成就刷新与领奖命令自身不会递归推进自身。调用方不得降低 durability 或绕过 executor。

### 时间字段

- `saved_at_unix`：成功提交快照中记录的写入尝试时间，仅审计。
- `last_seen_wall_unix`：单调诊断上界。
- `last_settled_unix`：最近一次成功离线结算时间，仅审计。
- `offline_anchor_unix`：唯一离线 accrual 起点。

### Receipt

命令 ID 绑定 canonical fingerprint；同 ID 同 fingerprint 返回原 receipt，同 ID 或 business key 复用但 fingerprint 不同会 hard error。canonical payload 只接受受控 JSON 值，公开命令校验精确字段与类型。价值 receipt 已写入存档；任务和成就完成与领取分离，claimed、generation、request fingerprint、durable claim ledger 和目录奖励对账已实现。

## 入口或路径

已实现路径见 [KM:reference.file-ownership](../indexes/file-ownership.md)，核心入口为 [CODE:command-executor](../../../project-a/game/scripts/commands/command_executor.gd)、[CODE:save-manager](../../../project-a/game/scripts/persistence/save_manager.gd) 和 [CODE:game-bootstrap](../../../project-a/game/scripts/autoloads/game.gd)。

## 验证

现有 Meta、Lifecycle、SLG loop、Research、First-30m、Platform 与浏览器 smoke 已覆盖候选写入、
保存失败不交换状态、重复命令、战斗结算 exact-once、v5/v6/v7 迁移、主备恢复、导入预览、
离线产出和刷新/离线重启。仍缺生产来源 crash/blocked-storage matrix、移动真机和长期真人会话。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。

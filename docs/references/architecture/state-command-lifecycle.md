---
km_id: reference.state-command-lifecycle
km_type: reference
domain: architecture
status: draft
owner: platform
last_verified: 2026-07-26
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

> **迁移警告（2026-07-26）：** candidate-save-commit、revision、fingerprint、receipt 和生命周期
> 规则继续有效；本文中的 schema v6 消耗单位、图纸研发和生死结算字段已过期。新状态与
> `damage_manifest` 见 [KM:reference.toilet-factory-technical-design](toilet-factory-technical-design.md)。

> 当前已实现 GameState schema 6、content `toilet-factory-siege-v6`、公开耐久命令、fingerprint、幂等、revision、先存后换、严格 JSON、主备恢复与 bootstrap gate。v5 有显式一次性迁移，schema 1–4 不再迁移。

> **已实现迁移：** schema v6 以双货币、型号图纸/科技、可消耗单位库存、六槽编队、抽取保底、任务/免费战令、生产队列和废料恢复替换了永久英雄等级/经验/星级、训练书、联盟残骸和旧金币的运行时权威。

## 目标

保证价值操作、任务进度、离线收益在单设备、单 writer、应用 crash/Android kill 范围内只产生一次效果。

## 事实

### 状态边界

- `GameState`：目标新版本持有马桶币、马桶钻来源账本、三材料、图纸、图纸数据、型号科技、生产队列、库存单位、六槽编队、研发保底、任务/战令和废料回收锚；具体 schema 号实施时确定。
- `achievements`：顶层五桶固定为 `progress`、`completed`、`claimed`、`event_keys`、`counters`。`progress/completed/claimed` 支持完成与手动领取分离；`event_keys` 使用 command_id 级别事件去重；`counters` 保存可靠回填后的单调计数。
- `FactoryState`：目标拥有三材料、型号图纸/数据/科技、最多三项生产队列、单调单位序列和废料回收锚。
- `BattleSession/BattleState`：目标用纯 GDScript 5Hz 承载 1–6 个实际部署单位、阶段、技能、炮击预警、生死标记和撤退请求；它不进入存档。
- `BattleResult`：必须包含胜利/全灭/超时/撤退、阵亡单位 ID、幸存单位 ID 和仅胜利时的马桶币/材料奖励，并由稳定 `battle_id` exact-once 提交。

### 命令分类

- `DURABLE_VALUE`：目标覆盖钱包变更、生产/领取、科技升级、图纸研发、任务/战令领奖、战斗生死结算、废料回收和设施升级。旧训练与三合一命令迁移后删除。
- `INTERNAL_DURABLE`：pause anchor、foreground heartbeat、resume/offline settlement 尚未实现。
- `REVERSIBLE_META`：commander + 六 troop 槽编队走立即提交；装备、筛选、重命名及 debounce 尚未实现。
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

现有 meta 测试只证明事务框架与遗留 schema。新版本必须新增钱包/库存/保底对账、生产/研发/战斗中断恢复、重复结算、旧档策略、600 replay、浏览器 crash matrix 和离线时钟证据。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。

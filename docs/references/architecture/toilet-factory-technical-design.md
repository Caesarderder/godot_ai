---
km_id: reference.toilet-factory-technical-design
km_type: reference
domain: architecture
status: draft
owner: programming
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/commands/command_executor.gd
validated_by:
  - manual-architecture-preflight-2026-07-26
tags:
  - reference:technical-design
  - risk:major-migration
related:
  - reference.architecture-overview
  - reference.file-ownership
  - reference.verification-matrix
  - reference.toilet-factory-refactor-plan
---

# 永久军团与工厂后勤技术设计

## 证据边界

本文是新玩法的程序交接草案，不代表已经实现。当前 schema v6 的消耗单位、图纸研发和永久阵亡
仍是运行时事实；新实现必须通过独立 schema、focused tests 和真实 UI 证据后才能升级状态。

## 目标架构

继续复用已有耐久内核：

- `CommandExecutor`：candidate clone、revision、fingerprint、先存后提交；
- `SaveCodec`/`SaveManager`：schema 迁移、主备恢复和严格 JSON；
- `BattleSession`：确定性 tick、三段攻城与领域事件；
- `BattleWorld`：只读投影；
- `StageCatalog`：城镇内容和章节顺序。

替换业务权威：

- `HeroState`：永久角色、等级、经验、星级、战备度、技能与派驻；
- `FactoryState`：设施、产速、容量、离线结算、加工与维修队列；
- `EconomyState`：工业资源、金币、工业技术与突破资源；
- `FormationState`：六槽永久 `hero_id`；
- `BattleSettlement`：`damage_manifest`、经验、战果和进度，不再删除单位。

## 数据流

```text
时间/离线差值
  → FactoryService.calculate_output
  → claim_factory_output command
  → candidate save → commit

UI command
  → CommandExecutor(candidate)
  ├→ HeroProgression / FactoryService / RepairService
  └→ SaveCodec → SaveManager → live state

Formation snapshot
  → BattleSession
  → outcome + reward_manifest + damage_manifest + xp_manifest
  → settle_battle command
  → 原子写入伤损、经验、奖励和关卡进度
```

## 目标状态契约

### HeroState

- `hero_id`
- `archetype_id`
- `level`
- `xp`
- `star`
- `readiness`
- `injury_flags`
- `skill_unlocks`
- `auto_skill_enabled`
- `assigned_facility_id`

### FactoryState

- `facilities[facility_id] = {level, state, last_claim_at}`
- `storage = {porcelain, parts, sludge_energy}`
- `capacities`
- `processing_orders`
- `repair_orders`
- `last_simulated_at`

### EconomyState

- `gold`
- `industrial_tech`
- `skill_chips`
- `breakthrough_items`
- durable ledger/receipts

### FormationState

- `front_1..3/back_1..3` 保存唯一 `hero_id`；
- 空槽允许；
- readiness 为零、角色不存在或重复引用时拒绝开战。

### BattleSettlement

- `battle_id`
- `stage_id`
- `outcome`
- `ticks`
- `deployed_hero_ids`
- `damage_manifest[hero_id]`
- `xp_manifest[hero_id]`
- `reward_manifest`
- `retreat_tick`

## 时间与离线结算

- 使用绝对时间戳和保存时记录的可信本地时间；
- 每次结算计算 `min(elapsed, storage_remaining / rate)`；
- 不逐秒模拟，不使用线程；
- 时间回拨不得产生负产出或复制产出；
- 新档最低资源设施始终可运行；
- 维修订单与资源生产使用同一时间推进服务，但分开结算和 receipt。

## 伤损与维修

- 战斗实时 HP 只存在于 `BattleSession`；
- 结算将战斗表现映射为 0–100 的 readiness 损失和可选 injury flag；
- `settle_battle` 只写伤损事实，不自动维修；
- `quick_repair`、`full_repair`、`start_timed_repair` 是独立命令；
- 基础维修只消耗工业资源，不能依赖金币；
- 重复 battle_id 或 repair business key 返回原 receipt。

## 存档迁移

建议新 schema 为 v7，具体版本由程序实现时确认：

1. 保留账号级设置、章节进度、任务可迁移计数和已拥有原型；
2. 将旧库存实例按 `model_id` 聚合为永久角色解锁；
3. 旧型号科技星级映射到角色星级上限，超出首切片部分封存；
4. 旧马桶币映射为金币；三材料保留但重新解释为工业资源；
5. 马桶钻、研发保底和图纸数据只保留为 legacy wallet，不进入 P0 UI；
6. 清空旧生产订单、单位库存和永久死亡引用；
7. 为每名角色初始化 100 readiness；
8. 迁移失败不得部分覆盖 v6 主档，保留备份和回滚入口。

## UI 状态边界

- App Shell 只消费领域 query/view model，不读取 legacy 字段；
- 工厂、军团、战区、目标四个顶层屏幕共享只读 header model；
- 页面本地只保存选中项、滚动位置和弹窗状态；
- 资源、升级、维修、派驻、出征和结算全部经 command；
- 结算页从 receipt 构建，不通过重新读取差值猜测结果。

## 性能与 Web

- Godot 4.6.3 Compatibility、typed GDScript、单线程；
- 工厂时间推进 O(设施数 + 维修槽数)，不逐单位、逐秒模拟；
- 844×390 为手机横屏设计画布与最低检查尺寸，`canvas_items + expand` 适配更大窗口；
- 3D 战斗继续使用对象池和表现事件，不增加后台自动战斗；
- 页面失焦时战斗暂停，设施离线时间在恢复后按时间戳结算。

## 架构决策

- 复用命令/存档/战斗内核，拒绝全项目推倒重写；
- 新增 `RepairService` 和设施目录，拒绝把维修逻辑塞进 UI；
- 用新 schema 一次迁移业务语义，拒绝让 v6/v7 两套权威长期并存；
- 先完成 headless 领域纵切，再迁 App Shell；
- Verdict：`READY_FOR_PLANNED_REFACTOR`，尚未 `IMPLEMENTED`。

## 长期进度扩展（已实现）

```text
CommandExecutor candidate
  → 原始领域事件
  → MetaProgressionService
  → MetaProgressionState
  → SaveCodec schema v8
```

- `MetaProgressionState` 持有指挥官经验、日周 generation、战令赛季、成就、事件去重和招募保底；
- `MetaCatalog` 持有 30 级曲线、8 个周期任务、30 项成就和 30 级免费战令奖励；
- `SignalRecruitService` 使用固定 seed、整数万分比、十抽 A、60 抽 S 和定向继承；
- `LogisticsService.upgrade_star` 在同一 candidate 内先消耗英雄专属数据，再以通用英雄数据补足，
  任一资源不足时不产生半扣款；
- `FormationService.assign_slot` 提供六槽单点部署与已上阵英雄互换，最终结果继续通过
  `FormationState.validate` 拒绝重复 hero_id；
- `MetaProgressionService.claimable_summary` 是无副作用查询，统一计算等级、任务、战令和成就的
  待领奖励数；成就批量领取仍通过命令事务修改账本；
- 战斗 UI 只调用 `BattleWorld.request_skill/set_auto_skill/request_retreat`，能量、存活和技能接受
  条件继续由 `BattleSession` 决定；`BattleWorld` 将每个确定性 tick 已用于 3D 同步的同一份
  snapshot 通过信号交给 HUD，避免 Web 单线程中额外定时深拷贝，也不把表现状态写回领域；
- `last_battle_runtime_result` 仅保留当前会话的复盘数据，持久战果与伤损仍以 `settle_battle`
  命令事件为权威，避免 UI 统计参与 exact-once 结算；
- `settle_battle` 持久化失败时保留原 payload 与 battle_id，进入阻断式恢复页并以相同 business key
  重试；不得把缺失 event 降级显示成普通战败，也不得允许玩家误以为战果已经保存；
- 领域事件在同一 candidate 事务内推进长期目标，UI 不直接修改持久状态；
- schema v5/v6 缺少 `meta_progression` 时迁移为安全默认值；schema v7 补入等级奖励领取账本；
  三者均不清除永久角色、工厂或进度。

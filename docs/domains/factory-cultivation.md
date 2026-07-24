---
km_id: domain.factory-cultivation
km_type: domain
domain: factory-cultivation
status: active
owner: gameplay
last_verified: 2026-07-24
source_of_truth:
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/recruitment/hero_generator.gd
  - project-a/tools/run_meta_tests.gd
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - python3 tools/docs_lint.py
tags:
  - domain:factory-cultivation
  - decision:p0-system
related:
  - domain.product
  - domain.hero-formation
  - reference.state-command-lifecycle
  - reference.file-ownership
  - reference.implementation-status
  - reference.skibidi-toilet-idle-siege-gdd
  - reference.earth-skibidi-act1-campaign
---

# 工厂与培育领域

## 目标

让玩家通过可见的工厂生产和永久升星，把“缺战力”转化为可执行的生产、等待、领取、合成和重新编队。

## 什么时候读

实现或修改材料、蓝图、生产队列、领取、英雄实例生成、3 合 1 升星、升星后编队引用或工厂 UI 时。

## 职责

- `FactoryCatalog` 当前提供 8 个稳定配方：`ordinary.assault`、`ordinary.sonic`、`flying.rocket`、`flying.bomber`、`heavy.armored`、`heavy.saw`、`special.repair`、`special.parasite`。
- 工厂材料键固定为 `porcelain`、`parts`、`sludge`；新档初始材料为 120/100/80，只开放 `ordinary.assault` 和 `ordinary.sonic`，其余六个蓝图在 UI 中锁定预览。
- 首败或超时解锁 `flying.rocket` 与 `heavy.armored` 作为反攻选项；首次胜利解锁 `flying.bomber`、`heavy.saw`、`special.repair`，摧毁核心后解锁 `special.parasite`。
- 战斗胜利结算返还 24/16/12 三材料和 1 本训练书；主力全灭返还 8/5/4 残骸和 2 本训练书，超时返还 4/3/2 残骸和 2 本训练书。失败收益显著低于胜利，但保证玩家能通过训练/生产完成首败后成长。
- 生产订单最多 3 个；`start_production` 开始时扣材料并写入 `order_id`、`recipe_id`、`started_at_unix`、`completes_at_unix`；`claim_production` 到点后从队列移除订单并生成一个永久英雄实例。`claim_ready_productions` 用同一绝对时间一次性领取离线期间已完成订单，仍走命令与 receipt。
- 新英雄 ID 由 `factory.next_hero_sequence` 单调分配，避免合成删除旧英雄后再次生产时复用 ID。
- 培育当前为同 `archetype_id`、同 `star` 的三个英雄合成一个更高星英雄；合成最多到 5 星。
- 合成消耗三个旧实例并新增一个实例；如果被消耗英雄在编队中，服务会用新英雄替换第一个编队引用，并拒绝会清空多个编队槽的合成。

## 长期剧情约束

- 当前切片只实现固定工厂；联盟反攻摧毁旧工厂、移动工厂重建和 Astro 母舰生产体系均属于长期设计，不能宣称已经落地。
- 旧工厂可在剧情中损失设施等级、生产效率、部分普通材料和区域控制权，但永久角色、星级、关键蓝图、传奇角色和长期收藏必须随核心数据库撤离。
- 剧情杀不能无预警清空材料或未完成订单；具体损失必须在章节前提示，并提供残骸回收、重建补偿或等价恢复路径。
- 移动工厂必须提供快速部署、战场回收、模块化生产或城市迁移等新行为，不能只是把固定工厂的升级树归零后重新购买。
- 通关后 Astro 战役使用独立阵营进度，不得覆盖或删除地球 Skibidi 工厂与角色；跨战役共享资源仍未决定。
- 第一幕正式内容不应开局开放全部八个蓝图；按普通、重装、飞行、特殊车间逐章解锁，详细顺序见 [KM:reference.earth-skibidi-act1-campaign](../references/product-design/earth-skibidi-act1-campaign.md)。

## 不是本层职责

不负责战斗伤害、关卡胜负、UI 节点布局、Web 持久性探测、装备强化或任务引导。

## 不变量

生产和合成都必须经 `CommandExecutor` 提交，不能由 UI 直接改 `GameState`。同一 `command_id` 或 business key 的重放必须返回原 receipt，不能重复扣材料、重复领取或重复生成英雄。

## 入口

[CODE:factory-state](../../project-a/game/scripts/state/factory_state.gd)、[CODE:factory-catalog](../../project-a/game/scripts/domain/factory/factory_catalog.gd)、[CODE:factory-service](../../project-a/game/scripts/domain/factory/factory_service.gd)、[CODE:command-executor](../../project-a/game/scripts/commands/command_executor.gd)。

## 验证

`tools/run_meta_tests.gd` 当前覆盖 8 配方目录、初始蓝图锁定、首败/胜利蓝图解锁、离线完成摘要、一键领取完成订单、开始生产扣材料、订单完成时间、未完成不可领取、领取生成永久英雄、重放不重复领取、三个装甲马桶人合成 2 星、合成后编队引用迁移、生产后的 ID 单调性、v2→v3 工厂数据迁移，以及未知配方/蓝图和超过三槽的存档拒绝。

## 相关节点

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)、[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

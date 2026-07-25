---
km_id: domain.camp-quests
km_type: domain
domain: camp-quests
status: active
owner: gameplay
last_verified: 2026-07-25
source_of_truth:
  - docs/references/constraints/product-boundaries.md
  - project-a/game/scripts/domain/quest/quest_catalog.gd
  - project-a/game/scripts/domain/quest/quest_service.gd
  - project-a/game/scripts/domain/achievement/achievement_catalog.gd
  - project-a/game/scripts/domain/achievement/achievement_service.gd
  - project-a/game/scripts/state/game_state.gd
  - project-a/scripts/main.gd
validated_by:
  - user-correction-review-2026-07-24
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - domain:camp-quests
  - decision:implemented-system
  - decision:soft-guidance
related:
  - domain.product
  - domain.equipment-economy
  - reference.product-boundaries
---

# 营地与任务领域

## 目标

记录已实现的营地“目标”中心：任务、成就与战功包装。基地首页通往工厂、培育、编队、目标和出征，不以旧酒馆/铁匠/训练场设施抢占攻城主循环。

## 什么时候读

设计设施、任务、成就、领域事件、目标进度、奖励或内容解锁时。

## 职责

- 当前提供工厂、培育、编队、目标和出征入口，以及不阻塞操作的动态行动提示；营地只有一个“目标”入口，入口内用“任务 / 成就”分页承载长期反馈。
- 已实现 25 个首胜大战役任务、3 槽无时限循环小任务、1–30 战功等级，以及 24 个永久一次性成就。酒馆、铁匠、训练场和设施升级仍延期。
- 成就目录固定为四类：战役 `6` 个、工厂 `3` 个、培育 `7` 个、收集 `8` 个。成就只读 `AchievementCatalog`，目标使用现有可靠计数器，不引入每日、周常、赛季或倒计时字段。
- `GameState` 当前为 schema v4 / content `factory-siege-v4`，顶层 `achievements` 使用五桶：`progress`、`completed`、`claimed`、`event_keys`、`counters`。
- 任务通过现有领域命令成功事件和 `QuestService` 推进；成就通过 `AchievementService` 消费成功事件并做可靠回填。二者不轮询、不按自然日刷新、不依赖广告或付费入口。
- 任务与成就只提供软引导和反馈；跳过目标中心仍可生产、培育和出征。
- Web 手机横屏 UI 使用单列列表：目标页顶部是任务/成就分页，成就页提供全部/战役/工厂/培育/收集分类筛选，按钮保持移动触控尺寸，列表禁止横向滚动。

## 不是本层职责

不定义工厂车间、生产队列、蓝图或英雄训练；这些属于当前 P0 的独立领域。也不做自由建造、人口模拟、关卡硬锁、每日/周常、FOMO、广告刷新、IAP、蓝图奖励或战力倍率。

## 不变量

任务和成就都必须完成与手动领取分离；完成只写入 `completed`，领取才发放奖励。领奖属于耐久价值操作，必须校验 generation、目录标准奖励、幂等流水和 claimed 状态。重复命令、重复点击、存档重载或篡改奖励不得复制或放大收益。

奖励白名单仅为 `merit`、`gold`、`xp_books`；不得给蓝图、付费货币、联盟残骸直发、概率抽卡、广告入口、生产加速券或战力倍率。旧档只允许用可靠证据回填：关卡完成、Boss 完成、`stage_5_5`、当前 roster 的等级/星级/原型、当前战功、首胜残骸可推导值、命令/耐久流水中的生产领取和残骸兑换；缺少流水的训练次数等动作历史不得猜测。

## 入口

[KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md)、[CODE:achievement-catalog](../../project-a/game/scripts/domain/achievement/achievement_catalog.gd)、[CODE:achievement-service](../../project-a/game/scripts/domain/achievement/achievement_service.gd)。

## 验证

`run_meta_tests.gd` 已覆盖 25 大任务、3 槽补位、事件推进、claim once、篡改奖励拒绝、旧档回填、30 级封顶、schema v4、24 个成就、成就 event key 去重、可靠回填、目录奖励对账与 durable claim ledger；`run_ui_smoke_tests.gd` 已覆盖单一“目标”入口、任务/成就分页、24 成就单列、分类筛选、领取态、触控高度和无横向滚动。真人长期留存与奖励数值仍未验证。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

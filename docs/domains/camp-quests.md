---
km_id: domain.camp-quests
km_type: domain
domain: camp-quests
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - project-a/game/scripts/domain/quest/quest_catalog.gd
  - project-a/game/scripts/domain/achievement/achievement_catalog.gd
validated_by:
  - manual-goal-system-migration-review-2026-07-26
tags:
  - domain:camp-quests
  - decision:p05-system
related:
  - domain.product
  - domain.equipment-economy
  - reference.implementation-status
  - reference.meta-progression-system
---

# 目标与任务领域

## 目标

使用自然行为目标、指挥官等级、免费战令与永久成就，为工厂成长、角色培养和城镇攻坚提供短中长期方向。

## 职责

- 任务围绕收取资源、升级设施、提升角色、处理伤损、通关和低损失胜利；
- 指挥官等级只承担账户进度、渐进解锁和身份展示，不直接乘算战力；
- 战令汇总日、周、章节目标，首期为 28 天 30 级免费轨；
- 成就记录永久里程碑，不重置，不把领奖行为作为价值生产目标；
- 完成与领取分离，领奖保持幂等；
- 章节里程碑可发金币、工业技术、角色碎片、Boss 核心或设施许可证；
- 结算最多突出三个下一目标，并优先推荐真实可执行行动；
- 旧任务/成就结构可迁移，旧马桶钻、图纸和制造单位奖励必须转换或废弃。

## 不是本层职责

不定义设施产速、角色升级成本、战斗掉落、招募概率或商业支付。任务不得成为体力、每日次数或主线硬锁。

## 不变量

任务只提供软引导；未领取奖励不阻止推图；奖励必须有稳定 reason code 和 claim-once 证据；
不得通过任务暗中恢复战备度来绕过维修经济。
战令、任务和成就不得互相监听领奖事件形成循环奖励。

## 验证

覆盖自然事件推进、完成/领取分离、奖励对账、重复点击、迁移和移动横屏目标页。

## 入口

[KM:reference.meta-progression-system](../references/product-design/meta-progression-system.md)。

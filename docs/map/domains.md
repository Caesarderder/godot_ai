---
km_id: map.domains
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - manual-plan-review
  - python3 tools/docs_lint.py
tags:
  - quality:domain-registry
related:
  - domain.product
  - domain.hero-formation
  - domain.battle-progression
  - domain.equipment-economy
  - domain.camp-quests
  - domain.platform-persistence
---

# 领域注册表

| Domain | 领域节点 | 职责摘要 | 实现定位入口 |
|---|---|---|---|
| `product` | [KM:domain.product](../domains/product.md) | 手机单机放置体验、30 分钟目标、范围 | 产品边界参考 |
| `hero-formation` | [KM:domain.hero-formation](../domains/hero-formation.md) | 随机英雄、培养、四槽编队 | 文件归属索引 |
| `battle-progression` | [KM:domain.battle-progression](../domains/battle-progression.md) | 5Hz 战斗、关卡、失败后成长再胜 | 架构与验证矩阵 |
| `equipment-economy` | [KM:domain.equipment-economy](../domains/equipment-economy.md) | 装备实例、词条、强化、资源收支 | 文件归属索引 |
| `camp-quests` | [KM:domain.camp-quests](../domains/camp-quests.md) | 薄营地、任务软引导、奖励 | 文件归属索引 |
| `platform-persistence` | [KM:domain.platform-persistence](../domains/platform-persistence.md) | 移动生命周期、存档、离线、UI 安全区 | 状态/命令/生命周期参考 |

通用控制域 `code|architecture|workflow|quality|agent-memory|cross-domain` 不单独创建产品领域节点。

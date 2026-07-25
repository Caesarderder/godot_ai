---
km_id: map.domains
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-24
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/quest/quest_service.gd
  - project-a/game/scripts/domain/achievement/achievement_service.gd
validated_by:
  - rg --files project-a
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - quality:domain-registry
related:
  - domain.product
  - domain.factory-cultivation
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
| `factory-cultivation` | [KM:domain.factory-cultivation](../domains/factory-cultivation.md) | 三材料工厂、八配方生产队列、领取生成英雄、同原型同星 3 合 1 升星 | 文件归属索引 |
| `hero-formation` | [KM:domain.hero-formation](../domains/hero-formation.md) | 英雄实例、星级、L1-L5 成长、六人 2×3 编队 | 文件归属索引 |
| `battle-progression` | [KM:domain.battle-progression](../domains/battle-progression.md) | 5Hz 确定性战斗、关卡、3D 表现契约、失败后成长再胜 | 架构与验证矩阵 |
| `equipment-economy` | [KM:domain.equipment-economy](../domains/equipment-economy.md) | 装备实例、词条、强化、资源收支 | 文件归属索引 |
| `camp-quests` | [KM:domain.camp-quests](../domains/camp-quests.md) | 薄营地、目标入口、任务、成就、战功软引导与奖励 | 文件归属索引 |
| `platform-persistence` | [KM:domain.platform-persistence](../domains/platform-persistence.md) | 移动生命周期、存档、离线、UI 安全区 | 状态/命令/生命周期参考 |

通用控制域 `code|architecture|workflow|quality|agent-memory|cross-domain` 不单独创建产品领域节点。

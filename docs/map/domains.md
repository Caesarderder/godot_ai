---
km_id: map.domains
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-26
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
| `product` | [KM:domain.product](../domains/product.md) | 永久军团、工厂后勤、城镇攻坚、战后维修与 30 分钟目标 | 产品边界参考 |
| `factory-cultivation` | [KM:domain.factory-cultivation](../domains/factory-cultivation.md) | 设施、三工业资源、离线生产、维修与研究 | 文件归属索引 |
| `hero-formation` | [KM:domain.hero-formation](../domains/hero-formation.md) | 永久角色、等级/星级/技能/战备度与六人 2×3 编队 | 文件归属索引 |
| `battle-progression` | [KM:domain.battle-progression](../domains/battle-progression.md) | 5Hz 自动攻城、城镇进度、撤退、伤损与战果 | 架构与验证矩阵 |
| `equipment-economy` | [KM:domain.equipment-economy](../domains/equipment-economy.md) | 工业资源、战争资源、招募券、永久英雄招募与账本 | 文件归属索引 |
| `camp-quests` | [KM:domain.camp-quests](../domains/camp-quests.md) | 行动任务、指挥官等级、免费战令、永久成就和软引导 | 文件归属索引 |
| `platform-persistence` | [KM:domain.platform-persistence](../domains/platform-persistence.md) | 移动生命周期、存档、离线、UI 安全区 | 状态/命令/生命周期参考 |

通用控制域 `code|architecture|workflow|quality|agent-memory|cross-domain` 不单独创建产品领域节点。

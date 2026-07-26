---
km_id: domain.product
km_type: domain
domain: product
status: active
owner: product-design
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - python3 tools/docs_lint.py
tags:
  - domain:product
  - decision:core-loop
related:
  - domain.factory-cultivation
  - domain.hero-formation
  - domain.equipment-economy
  - domain.battle-progression
  - reference.product-boundaries
  - reference.game-state-measurement-framework
---

# 产品领域

## 目标

做一款手机横屏 3D 轻量 SLG：工厂持续提供后勤资源，玩家永久培养马桶人军团，主动攻占城镇，
用金币、经验和工业技术扩建基地，并处理每场战斗留下的可修复伤损。

## 职责

- 维护“收资源—养军团—攻城—受损—维修—扩厂—再攻城”循环；
- 保护永久角色、工厂后勤、主动城镇攻坚和战后决策四个支柱；
- 控制第一切片为四角色、三星、六设施、三资源、四城镇和一个 Boss；
- 确保无体力、无自动推图、无量产马桶人、无永久角色删除；
- 区分接受设计与 schema v6 旧实现，迁移完成前不得宣称新玩法已实现。
- 使用统一度量语言解释推进能力、后勤续航、成长节奏和内容寿命，不能只用总战力或资源余额判断健康。

## 不是本层职责

不决定 GDScript 类、场景树、存档算法、具体 UI 节点或最终数值。

## 不变量

工厂必须影响角色成长和维修；战果必须影响工厂扩建；伤损必须产生可理解选择；失败不能死档；
任务与商业系统不得替代主动攻城。

## 入口

[KM:reference.game-contract](../game-contract.md)、
[KM:reference.skibidi-toilet-idle-siege-gdd](../references/product-design/skibidi-toilet-idle-siege-gdd.md)、
[KM:reference.product-boundaries](../references/constraints/product-boundaries.md)。
[KM:reference.game-state-measurement-framework](../references/product-design/game-state-measurement-framework.md)。

## 验证

以 [KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md) 为最小真人与自动验收合同。

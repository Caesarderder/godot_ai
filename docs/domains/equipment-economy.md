---
km_id: domain.equipment-economy
km_type: domain
domain: equipment-economy
status: draft
owner: gameplay
last_verified: 2026-07-24
source_of_truth:
  - docs/references/constraints/product-boundaries.md
validated_by:
  - user-correction-review-2026-07-24
tags:
  - domain:equipment-economy
  - decision:p1-system
related:
  - domain.product
  - domain.hero-formation
  - reference.first-30m-contract
---

# 装备与经济领域

## 目标

记录 P1 候选装备经济，供核心“工厂生产—培育—攻城”闭环稳定后评估。装备不是当前首 30 分钟门禁，也不能取代配方、星级和阵型的策略价值。

## 什么时候读

设计掉落、装备实例、词条、品质、强化、背包、资源 source/sink 或 pity 时。

## 职责

- 若进入 P1，静态装备模板与运行实例分离；实例保存品质、随机词条、强化等级和稳定 ID。
- 武器/防具/饰品、品质、强化和 pity 均为候选设计，实施前需重新做数值与范围确认。
- 当前 P0 经济以生产材料、金币、训练书和蓝图进度服务工厂与永久培育；不再使用招募券作为主循环资源。
- 当前首 30 分钟的成长证明来自生产、三合一、训练、技能质变和换阵，不依赖稀有装备保底。

## 不是本层职责

不定义关卡 unlock、任务条件或英雄成长公式。

## 不变量

装备不能取代八原型、星级技能质变或阵型差异；若实现强化，失败不得损失且结果必须可持久重放、不重复。

## 入口

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

## 验证

当前仅验证 P0 没有隐式依赖装备。装备进入实施后再建立 ledger、pity golden、强化 source/sink 与重复结算/杀进程矩阵。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。
